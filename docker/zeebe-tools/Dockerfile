# Dockerfile for the “zeebe-tools” image, used by operators to look
# around and fix things

FROM ubuntu:focal

RUN set -e -x; \
    runtime_packages="curl openjdk-17-jre-headless perl-modules-5.30 \
                    libdata-messagepack-perl libjson-perl"; \
    build_packages="build-essential libperl-dev git cpanminus"; \
    apt -qy update; \
    DEBIAN_FRONTEND=noninteractive apt -qy install $runtime_packages $build_packages; \
    cpanm Date::Parse URI::Escape Crypt::Rhash File::Find File::Slurp; \
    cpanm --installdeps RocksDB; \
    git clone -b fix/build-on-modern-ubuntu https://github.com/epfl-si/RocksDB; \
    ( cd RocksDB; \
      perl Build.PL; \
      ./Build; \
      ./Build install; \
    ); \
    apt -qy remove --auto-remove $build_packages; \
    apt -q clean; \
    rm -rf /root/.cpanm /root/RocksDB

RUN set -e -x; \
  for download in zdb zdb.jar; do \
    curl -L -o /usr/local/bin/$download https://github.com/Zelldon/zdb/releases/latest/download/$download; \
  done; \
  chmod 755 /usr/local/bin/zdb
