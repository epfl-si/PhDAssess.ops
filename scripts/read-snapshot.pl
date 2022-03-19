#!/usr/bin/perl

use strict;
use warnings qw(all);
use RocksDB;
use Data::MessagePack;
use JSON;
use URI::Escape;

binmode STDOUT, ':utf8';

my $db = RocksDB->new($ARGV[0]);

my $iter = $db->new_iterator->seek_to_first;
while (my ($key, $value) = $iter->each) {
  $key = parse_key($key);
  $value = parse_value($value);
  printf "%s: %s\n", $key, $value;
}

our $jsonist; BEGIN { $jsonist = JSON->new->canonical->convert_blessed; }
sub parse_value {
  my $packed = shift;

  if (my $msgunpacked = eval { Data::MessagePack->unpack($packed) }) {
    $msgunpacked = summarize_strings($msgunpacked);
    if (my $json = eval { $jsonist->encode($msgunpacked) }) {
      return $json;
    }
  }

  return summarize_strings($packed);
}

sub summarize_strings {
  my $wat = shift;

  if (ref($wat) eq "HASH") {
    return { map { summarize_strings($_) } %$wat };
  } elsif (ref($wat) eq "ARRAY") {
    return [ map { summarize_strings($_) } @$wat ];
  } elsif (ref($wat)) {
    return $wat;
  }

  local $_ = $wat;
  if (length() > 500) {
    $_ = sprintf("%s[...%d...]%s", substr($_, 0, 25), length() - 50,
                   substr($_, length() - 25, 25));
  }
  if (m/[\N{U+00}-\N{U+1f}]/ || m/\N{U+FF}/) {
    $_ = uri_escape_utf8($_);
  }
  return $_;
}

sub Data::MessagePack::Boolean::TO_JSON {
  my $self = shift;
  if ($$self) { return "true" } else { return "false" }
}

sub parse_key {
  my ($key) = @_;
  my @toks;
  unless (@toks = Tok::ColumnFamily->take($key)) {
    return sprintf("<No column family? %s>", parse_value($key));
  }

  TOK: while(length $key) {
    if (my $tok = Tok::Int64->take($key) ||
        Tok::String->take($key)) {
      push @toks, $tok;
    } else {
      # Skip one byte, try again
      push @toks, Tok::Garbage->new unless $toks[$#toks]->can("cram");
      $toks[$#toks]->cram(substr($key, 0, 1, ""));
    }
  }

  return join(" ", map { $_->pretty } @toks);
}

sub unpack_int64 {
  my ($bytes) = @_;
  die unless length($bytes) == 8;
  my $num = unpack("Q", reverse($bytes));
  return undef unless $num % (2**48) < 2**32;
  return $num;
}

package Tok;

sub take {
  my $class = shift;
  return unless my $self = $class->peek(@_);
  substr($_[0], 0, $self->bytes_length, "");
  return $self;
}

package Tok::Int64;

use base qw(Tok);

sub bytes_length { 8 }

sub peek {
  my $class = shift;
  return undef unless 8 == length(my $bytes = substr($_[0], 0, 8));
  my $num = unpack("Q", reverse($bytes));
  return undef unless $num % (2**48) < 2**32;
  bless \$num, $class;
}

sub pretty { ${$_[0]} }

package Tok::ColumnFamily;

use base qw(Tok::Int64);

# as per `public enum ZbColumnFamilies`, from the Book of
# zeebe/engine/src/main/java/io/camunda/zeebe/engine/state/ZbColumnFamilies.java:

our @ZbColumnFamilies; BEGIN { @ZbColumnFamilies = qw(
  DEFAULT
  KEY
  PROCESS_VERSION

  PROCESS_CACHE PROCESS_CACHE_BY_ID_AND_VERSION PROCESS_CACHE_DIGEST_BY_ID

  ELEMENT_INSTANCE_PARENT_CHILD ELEMENT_INSTANCE_KEY
  NUMBER_OF_TAKEN_SEQUENCE_FLOWS

  ELEMENT_INSTANCE_CHILD_PARENT  VARIABLES
  TEMPORARY_VARIABLE_STORE

  TIMERS  TIMER_DUE_DATES  PENDING_DEPLOYMENT  DEPLOYMENT_RAW

  JOBS JOB_STATES JOB_DEADLINES JOB_ACTIVATABLE

  MESSAGE_KEY MESSAGES MESSAGE_DEADLINES MESSAGE_IDS
  MESSAGE_CORRELATED MESSAGE_PROCESSES_ACTIVE_BY_CORRELATION_KEY
  MESSAGE_PROCESS_INSTANCE_CORRELATION_KEYS

  MESSAGE_SUBSCRIPTION_BY_KEY MESSAGE_SUBSCRIPTION_BY_SENT_TIME
  MESSAGE_SUBSCRIPTION_BY_NAME_AND_CORRELATION_KEY

  MESSAGE_START_EVENT_SUBSCRIPTION_BY_NAME_AND_KEY
  MESSAGE_START_EVENT_SUBSCRIPTION_BY_KEY_AND_NAME

  PROCESS_SUBSCRIPTION_BY_KEY
  PROCESS_SUBSCRIPTION_BY_SENT_TIME

  INCIDENTS
  INCIDENT_PROCESS_INSTANCES
  INCIDENT_JOBS

  EVENT_SCOPE
  EVENT_TRIGGER

  BLACKLIST

  EXPORTER

  AWAIT_WORKLOW_RESULT

  JOB_BACKOFF
)};

sub pretty {
  my ($self) = @_;
  my $cf_name = $ZbColumnFamilies[$$self] || "(unknown)";
  "<$cf_name>";
}

package Tok::String;

use base qw(Tok);

sub peek {
  my ($class, $bytes) = @_;
  return unless my $len = unpack("N", $bytes);  # Not zero
  return unless $len == length(my $str = substr($bytes, 4, 4 + $len));
  return if $str =~ m/[\N{U+00}-\N{U+1f}]/;
  bless {
    str => $str
  }, $class;
}

sub bytes_length { 4 + length(shift->{str}) }

sub pretty { shift->{str} }

package Tok::Garbage;

sub new { bless { bin => "" }, shift }

sub cram {
  my ($self, $moar) = @_;
  $self->{bin} .= $moar;
}

sub pretty {
  main::parse_value(shift->{bin})
}
