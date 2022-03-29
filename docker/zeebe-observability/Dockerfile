# This image continuously inspects the Zeebe state for monitoring purposes

FROM docker-registry.default.svc:5000/phd-assess-test/zeebe-tools

RUN mkdir /dancer
WORKDIR /dancer
COPY cpanfile /dancer

RUN set -e -x; \
    runtime_packages="libdancer2-perl libtemplate-perl libcrypt-cbc-perl"; \
    not_really_a_runtime_package_but_we_keep_it_anyway="make"; \
    build_packages="build-essential cpanminus libssl-dev"; \
    apt -qy update; \
    DEBIAN_FRONTEND=noninteractive apt -qy install $runtime_packages \
      $build_packages $not_really_a_runtime_package_but_we_keep_it_anyway; \
    cpanm --installdeps --notest . ; \
    apt -qy remove --auto-remove $build_packages; \
    apt -q clean; \
    rm -rf /root/.cpanm /var/lib/apt/lists

ADD https://fastapi.metacpan.org/source/METZZO/Java-4.7/JavaServer.jar /usr/local/lib/
COPY PerlBiConsumer.java /dancer
# Build it hermetically into /usr/local/lib/PerlBiConsumer.jar:
RUN set -e -x; \
    java_build_packages="openjdk-17-jdk-headless"; \
    apt -qy update; \
    DEBIAN_FRONTEND=noninteractive apt -qy install $java_build_packages; \
    javac -classpath /usr/local/lib/JavaServer.jar:/usr/local/bin/zdb.jar PerlBiConsumer.java; \
    jar cvf /usr/local/lib/PerlBiConsumer.jar PerlBiConsumer.class; \
    apt -qy remove --auto-remove $java_build_packages; \
    apt -q clean; \
    rm -rf /var/lib/apt/lists

COPY . /dancer

RUN set -e -x; \
    perl Makefile.PL; \
    make ; \
    make install

EXPOSE 5000
CMD plackup bin/app.psgi
