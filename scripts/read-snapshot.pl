#!/usr/bin/perl

use strict;
use warnings qw(all);
use RocksDB;
use Data::MessagePack;
use JSON;
use URI::Escape;

binmode STDOUT, ':utf8';

my $db = RocksDB->new('/Users/quatrava/Dev/PhDassess/snapshots/65006208-50-65412316-65412297');

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
  unless (@toks = Tok::Int64Tag->take($key)) {
    return sprintf("<no tag? %s>", parse_value($key));
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

package Tok::Int64Tag;

use base qw(Tok::Int64);

sub pretty {
  my ($self) = @_;
  sprintf("<tag %d>", $self->SUPER::pretty);
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
