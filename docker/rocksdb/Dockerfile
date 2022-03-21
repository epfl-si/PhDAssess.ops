# As it turns out, upstream https://github.com/spiritloose/RocksDB is
# quite tightly coupled to the year 2018:
FROM ubuntu:bionic

RUN set -e -x; \
    apt -qy update; \
    apt -qy install build-essential librocksdb5.8 librocksdb-dev libperl-dev git cpanminus; \
    cpanm --installdeps RocksDB; \
    cpanm --force RocksDB; \
    apt -qy remove --auto-remove build-essential librocksdb-dev libperl-dev git cpanminus; \
    apt -q clean
