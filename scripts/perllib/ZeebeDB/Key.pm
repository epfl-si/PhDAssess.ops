=head1 NAME

C<ZeebeDB::Tok> - Parse the RocksDB keys we can find in a Zeebe database

=cut

package ZeebeDB::Key;

sub parse {
  my ($class, $key) = @_;
  my $cf;
  unless ($cf = ZeebeDB::Key::Tok::ColumnFamily->take($key)) {
    return sprintf("<No column family? %s>", ZeebeDB::Key::Tok::String->pretty($key));
  }
  my @toks = ($cf);

  TOK: while(length $key) {
    if (my $tok = ZeebeDB::Key::Tok::ZeebeKey->take($key) ||
        ZeebeDB::Key::Tok::String->take($key) ||
        ZeebeDB::Key::Tok::Timestamp->take($key)) {
      push @toks, $tok;
    } else {
      # Skip one byte, try again
      push @toks, ZeebeDB::Key::Tok::Garbage->new unless $toks[$#toks]->can("cram");
      $toks[$#toks]->cram(substr($key, 0, 1, ""));
    }
  }

  return wantarray ? @toks : join(" ", map { $_->pretty } @toks);
}


package ZeebeDB::Key::Tok;

sub take {
  my $class = shift;
  return unless my $self = $class->peek(@_);
  substr($_[0], 0, $self->bytes_length, "");
  return $self;
}

sub TO_JSON { shift->pretty }

package ZeebeDB::Key::Tok::Int64;

use base qw(ZeebeDB::Key::Tok);

sub bytes_length { 8 }

sub peek {
  my $class = shift;
  return undef unless 8 == length(my $bytes = substr($_[0], 0, 8));
  my $num = unpack("Q", reverse($bytes));
  bless { num => $num }, $class;
}

sub pretty  { shift->{num} }

package ZeebeDB::Key::Tok::ZeebeKey;

use base qw(ZeebeDB::Key::Tok::Int64);

sub peek {
  my $class = shift;
  return unless my $self = $class->SUPER::peek(@_);
  return ($self->{num} % (2**48) < 2**32) ? $self : undef;
}

package ZeebeDB::Key::Tok::ColumnFamily;

use base qw(ZeebeDB::Key::Tok::Int64);

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

sub name { my $self = shift; $ZbColumnFamilies[$self->{num}] || "(unknown)" }

sub pretty {
  my ($self) = @_;
  my $cf_name = $self->name;
  "<$cf_name>";
}

package ZeebeDB::Key::Tok::String;

use base qw(ZeebeDB::Key::Tok);
use URI::Escape;

sub peek {
  my ($class, $bytes) = @_;
  return unless my $len = unpack("N", $bytes);  # Not zero
  return unless $len == length(my $str = substr($bytes, 4, $len));
  return if $str =~ m/[\N{U+00}-\N{U+1f}]/;
  bless {
    str => $str
  }, $class;
}

sub bytes_length { 4 + length(shift->{str}) }

sub pretty {
  my $self = shift;
  local $_ = ref($self) ? $self->{str} : shift;
  if (length() > 500) {
    $_ = sprintf("%s[...%d...]%s", substr($_, 0, 25), length() - 50,
                   substr($_, length() - 25, 25));
  }
  if (m/[\N{U+00}-\N{U+1f}]/ || m/\N{U+FF}/) {
    $_ = uri_escape_utf8($_);
  }
  return $_;
}

package ZeebeDB::Key::Tok::Garbage;

use base qw(ZeebeDB::Key::Tok);

sub cram {
  my ($self, $moar) = @_;
  $self->{bytes} .= $moar;
}

sub pretty { ZeebeDB::Key::Tok::String->pretty(shift->{bytes}) }

package ZeebeDB::Key::Tok::Timestamp;

use base qw(ZeebeDB::Key::Tok::Int64);
use Date::Parse;
use Math::BigInt;

our ($timestamp_min, $timestamp_max); BEGIN {
  ($timestamp_min, $timestamp_max) =
    map { 1000 * Math::BigInt->new(str2time($_)) }
    ("Jan  1 00:00:00 2020",
     "Jan  1 00:00:00 2030");
}

sub peek {
  my $class = shift;
  return unless my $self = $class->SUPER::peek(@_);
  return ($self->{num} >= $timestamp_min && $self->{num} <= $timestamp_max) ?
    bless { millis => new Math::BigInt($self->{num}) }, $class            :
    undef;
}

sub pretty {
  scalar localtime(shift->{millis}->bdiv(1000));
}
sub TO_JSON { shift->{millis}->to_base(10) }
