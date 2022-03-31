#!/usr/bin/perl

use strict;
use warnings qw(all);

=head1 NAME

C<read-snapshot.pl> - Decode a RocksDB snapshot produced by Zeebe

=head1 SYNOPSIS

  read-snapshot.pl <dir>

Produces a text report to standard output

  read-snapshot.pl <dir> <outdir>

Produces a structured JSON report as a set of JSONL files in
C<outdir>, each corresponding to one of the Zeebe RocksDB column
families. The files contain many lines of text, each consisting of a
dict-typed JSON expression (“JSONL“ format), suitable for reading from
C<jq> or R's L<arrow|https://arrow.apache.org/docs/r/>.

=cut

use RocksDB;
use Data::MessagePack;
use JSON;
use FindBin qw($Bin);
use lib "$Bin/../docker/zeebe-tools/perllib";
use ZeebeDB::Key;

binmode STDOUT, ':utf8';

my $db = RocksDB->new($ARGV[0]);
our $targetdir = $ARGV[1];  # Optional

our $jsonist; BEGIN { $jsonist = JSON->new->canonical->convert_blessed; }

my $iter = $db->new_iterator->seek_to_first;
while (my ($key, $value) = $iter->each) {
  $value = parse_value($value);
  if ($targetdir) {
    emit_structured_json($targetdir, ZeebeDB::Key->parse($key), $value);
  } else {
    $key = ZeebeDB::Key->parse($key);
    if (my $json = eval { $jsonist->encode($value) }) {
      $value = $json;
    } else {
      $value = "<???>";
    }

    printf "%s: %s\n", $key, $value;
  }
}

sub parse_value {
  my $packed = shift;

  if (my $msgunpacked = eval { Data::MessagePack->unpack($packed) }) {
    return summarize_strings($msgunpacked);
  } else {
    return summarize_strings($packed);
  }
}

my %fds;
sub emit_structured_json {
  my ($targetdir, @kv) = @_;
  my $cf = shift @kv;
  my $cfname = UNIVERSAL::can($cf, "name") ? $cf->name : $cf;
  $fds{$cfname} ||= do {
    my $filename = "$targetdir/$cfname.json";
    my $fd = IO::File->new($filename, "w")
      or die "$filename: $!";
    $fd->binmode(":utf8");
    $fd;
  };

  my $data = pop @kv;
  $data = ref($data) ? {%$data} : { data => $data };
  # Now in @kv there are only key fragments. Find a helpful
  # name for them to put into the JSON:
  my %stem_seq;
  foreach my $k (@kv) {
    my ($keystem) = ref($k) =~ m/^.*::(.*)$/;
    $keystem = lc($keystem);
    my $keyname = $keystem . ++$stem_seq{$keystem};
    $data->{$keyname} = $k;
  }

  $fds{$cfname}->write($jsonist->encode($data) . "\n");
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

  return ZeebeDB::Key::Tok::String->pretty($wat);
}

sub Data::MessagePack::Boolean::TO_JSON {
  my $self = shift;
  if ($$self) { return "true" } else { return "false" }
}
