#!/usr/bin/env perl

use strict;
use warnings qw(all);
use v5.21;

=head1 NAME

C<decrypt-json.pl> - Decrypt (or clarify) all the fields in a PhDAssess database dump

=head1 SYNOPSIS

  decrypt-json.pl mydump.json

JSON and JSONL files are supported.

=cut

use Crypt::CBC;
use Crypt::OpenSSL::AES;
use MIME::Base64;
use JSON;
use FindBin qw($Bin $Script);

sub read_env_file {
  my ($path) = @_;

  open(my $env_fd, "<", "$path")
    or die "open($path): $!";

  my %env;
  while(<$env_fd>) {
    chomp;
    next unless my ($k, $v) = m/^(.*?)=(.*)$/;
    $env{$k} = $v;
  }
  return wantarray ? %env : \%env;
}

our $cipher = do {
  my %env = read_env_file("$Bin/../.env");

  Crypt::CBC->new(
        -key    => $env{PHDASSESS_ENCRYPTION_KEY},
        -cipher => "Crypt::OpenSSL::AES");
};

our $decrypt_successful = 0;
our $decrypt_failed = 0;

END {
  warn "$decrypt_successful successful decrypts, $decrypt_failed failed";
}

sub decrypt {
  my ($struct) = @_;

  if (ref($struct) eq "HASH") {
    return { map { decrypt($_) } %$struct };
  } elsif (ref($struct) eq "ARRAY") {
    return [ map { decrypt($_) } @$struct ];
  }

  local $_ = $struct;
  if (m/^(\d{13})$/) {
    return scalar localtime($_ / 1000);
  } elsif (m/^U2Fsd/) {
    my $decrypted;
    if (! eval {
      my $decoded = decode_base64($struct);
      $decrypted = $cipher->decrypt($decoded);
      1;
    }) {
      warn $@;
      $decrypt_failed++;
      return $struct;
    }

    $decrypt_successful++;

    my $retval;
    if (eval { $retval = decode_json($decrypted); 1 }) {
      return $retval;
    }

    # Truncated (yet stilld decipherable) input:
    if ($decrypted =~ m/^"/) {
      if ($decrypted =~ m/[\\]$/) {
        $decrypted .= '\\';
      }
      return decode_json($decrypted . '..."');
    }
  }
  return $struct;
}

#########################################################################

die "usage: $Script <jsonfile>\n" unless scalar(@ARGV) == 1;
my ($json_from) = @ARGV;
my $json_to = "${json_from}.new";
my $json_bak = "${json_from}.bak";

open(my $json_from_fd, "<", $json_from) or
  die("open($json_from): $!");
open(my $json_to_fd, ">", $json_to) or
  die("open($json_to): $!");

while(<$json_from_fd>) {
  chomp;
  my $struct = decode_json($_);
  $struct = decrypt($struct);
  $json_to_fd->print(encode_json($struct) . "\n");
}

close($json_to_fd) or die "close($json_to): $!";
rename($json_from, $json_bak) or die "rename($json_from, $json_bak): $!";
rename($json_to, $json_from) or die "rename($json_to, $json_from): $!";
