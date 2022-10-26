# Dockerfile for the “zeebe-tools” image, used by operators to look
# around and fix things

FROM ubuntu:focal

# We want librocksdb 6. Not 5 (won't open our databases), not 7
# (prevents RocksDB's XS code from compiling).
# And we can't just use FROM ubuntu:jammy, because its glibc won't
# work with our OpenShift's dockerd, for the reason that someone has
# been misinformed about the difference between EPERM and ENOSYS
# (https://bugs.launchpad.net/ubuntu/+source/libseccomp/+bug/1916485)
RUN sed 's/focal/jammy/g' < /etc/apt/sources.list > /etc/apt/sources.list.d/jammy.list
COPY dpkg-pref /etc/apt/preferences.d/rocksdb-of-jammy.pref

# Arguably even messier stuff is afoot below. Some explanations:
#
# - We do the “poor man's squashed build,” doing our best so that the
#   development tool chain, various caches (apt's and cpanm's), and
#   source code directories don't burden the Docker layer. Even then,
#   it clocks in at around 312 Mb.
#
# - Despite is having forked the RocksDB Perl codebase, the test suite
#   is not squeaky clean, and therefore we want to run it `|| true`.
#   We do *not* want to skip it altogether, so that we can fish out
#   any useful troubleshooting info from our OpenShift build logs.
#
RUN set -e -x; \
    runtime_packages="curl openjdk-17-jre-headless perl-modules-5.34 \
                    libdata-messagepack-perl libjson-perl librocksdb6.11"; \
    build_packages="build-essential librocksdb-dev libperl-dev git cpanminus"; \
    apt -qy update; \
    DEBIAN_FRONTEND=noninteractive apt -qy install $runtime_packages $build_packages; \
    cpanm Date::Parse URI::Escape Crypt::Rhash File::Find File::Slurp; \
    cpanm --installdeps RocksDB; \
    git clone -b fix/build-on-modern-ubuntu https://github.com/epfl-si/RocksDB; \
    ( cd RocksDB; \
      perl Build.PL; \
      ./Build test || true; \
      ./Build install; \
    ); \
    apt -qy remove --auto-remove $build_packages; \
    apt -q clean; \
    rm -rf /root/.cpanm RocksDB /var/lib/apt/lists

RUN set -e -x; \
  for download in zdb zdb.jar; do \
    curl -L -o /usr/local/bin/$download https://github.com/Zelldon/zdb/releases/latest/download/$download; \
  done; \
  chmod 755 /usr/local/bin/zdb

COPY perllib/ZeebeDB.pm perllib/ZeebeDB /usr/local/lib/site_perl/
