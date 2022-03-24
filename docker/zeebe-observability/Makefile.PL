use strict;
use warnings;
use ExtUtils::MakeMaker;

# Normalize version strings like 6.30_02 to 6.3002,
# so that we can do numerical comparisons on it.
my $eumm_version = $ExtUtils::MakeMaker::VERSION;
$eumm_version =~ s/_//;

WriteMakefile(
    NAME                => 'EPFL::Zeebe::Observability',
    AUTHOR              => q{EPFL ISAS-FSD <isas-fsd@groupes.epfl.ch>},
    VERSION_FROM        => 'lib/EPFL/Zeebe/Observability.pm',
    ABSTRACT            => 'Take a look at what is going on inside Zeebe',
    ($eumm_version >= 6.3001
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'YAML'       => 0,
        'Dancer2'     => 0.400000,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'EPFL-Zeebe-Observability-*' },
);
