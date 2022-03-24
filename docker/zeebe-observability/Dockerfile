# This image continuously inspects the Zeebe state for monitoring purposes

FROM docker-registry.default.svc:5000/phd-assess-test/zeebe-tools

RUN mkdir /dancer
WORKDIR /dancer
COPY cpanfile /dancer

RUN set -e -x; \
    runtime_packages="libdancer2-perl libtemplate-perl"; \
    not_really_a_runtime_package_but_we_keep_it_anyway="make"; \
    build_packages="cpanminus"; \
    apt -qy update; \
    DEBIAN_FRONTEND=noninteractive apt -qy install $runtime_packages \
      $build_packages $not_really_a_runtime_package_but_we_keep_it_anyway; \
    cpanm --installdeps --notest . ; \
    apt -qy remove --auto-remove $build_packages; \
    apt -q clean; \
    rm -rf /root/.cpanm /var/lib/apt/lists

COPY . /dancer

RUN set -e -x; \
    perl Makefile.PL; \
    make ; \
    make install

EXPOSE 5000
CMD plackup bin/app.psgi
