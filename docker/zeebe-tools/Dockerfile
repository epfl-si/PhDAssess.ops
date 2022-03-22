# Dockerfile for the “zeebe-tools” image, used by operators to look
# around and fix things

# As it turns out, upstream https://github.com/spiritloose/RocksDB is
# quite tightly coupled to the year 2018:
FROM ubuntu:bionic

RUN set -e -x; \
    runtime_packages="curl librocksdb5.8 openjdk-17-jre-headless perl-modules-5.26 \
                    libdata-messagepack-perl libjson-perl"; \
    build_packages="build-essential librocksdb-dev libperl-dev git cpanminus"; \
    apt -qy update; \
    apt -qy install $runtime_packages $build_packages; \
    cpanm Date::Parse URI::Escape; \
    cpanm --installdeps RocksDB; \
    cpanm --force RocksDB; \
    apt -qy remove --auto-remove $build_packages; \
    apt -q clean; \
    rm -rf /root/.cpanm

RUN set -e -x; \
  for download in zdb zdb.jar; do \
    curl -L -o /usr/local/bin/$download https://github.com/Zelldon/zdb/releases/latest/download/$download; \
  done; \
  chmod 755 /usr/local/bin/zdb
