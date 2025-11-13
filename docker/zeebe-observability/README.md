# Develop

```
perl Makefile.PL
make
env ZEEBE_OBSERVABILITY_DATA_DIR=$PWD/../../snapshots plackup -R lib/ -r bin/app.psgi
```
