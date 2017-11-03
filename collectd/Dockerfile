FROM ubuntu:16.04

ENV DEBIAN_FRONTEND noninteractive
ENV ROOT_FS_DIR_PATH ${COLLECTD_ROOTFS_DIR:-/usr/src/rootfs_prefix/}

COPY rootfs_prefix/ ${ROOT_FS_DIR_PATH}

RUN apt-get -y update \
    && apt-get install -qqy \
        build-essential=12.1ubuntu2 \
        mlocate=0.26-1ubuntu2 \
        libriemann-client-dev=1.8.1-2build1 \
        libxml2-dev=2.9.3+dfsg1-1ubuntu0.3 \
        libgeos++-dev=3.5.0-1ubuntu2 \
        libpq-dev=9.5.9-0ubuntu0.16.04 \
        libbz2-dev=1.0.6-8 \
        libtool=2.4.6-0.1 \
        automake=1:1.15-4ubuntu1 \
        protobuf-compiler=2.6.1-1.3 \
        libprotobuf-dev=2.6.1-1.3 \
        libprotoc-dev=2.6.1-1.3 \
        wget=1.17.1-1ubuntu1.3 \
        git=1:2.7.4-0ubuntu1.3 \
        dh-autoreconf=11 \
        pkg-config=0.29.1-0ubuntu1 \
    && make -C ${ROOT_FS_DIR_PATH}

RUN cd /home && wget https://github.com/protobuf-c/protobuf-c/releases/download/v1.2.1/protobuf-c-1.2.1.tar.gz \
    && tar xf protobuf-c-1.2.1.tar.gz \
    && cd protobuf-c-1.2.1 \
    && ./configure \
    && make \
    && make install

RUN cd /home \
    && wget  https://github.com/algernon/riemann-c-client/releases/download/riemann-c-client-1.9.1/riemann-c-client-1.9.1.tar.xz \
    && tar xf riemann-c-client-1.9.1.tar.xz \
    && cd riemann-c-client-1.9.1 \
    && libtoolize --force \
    && autoreconf -i \
    && ./configure \
    && make && make check && make install

RUN cd /home && wget https://storage.googleapis.com/collectd-tarballs/collectd-5.7.1.tar.bz2 \
    && tar xf collectd-5.7.1.tar.bz2 \
    && cd collectd-5.7.1 && ./configure --enable-all-plugin && make all install

RUN apt-get -y --purge remove build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENTRYPOINT chmod -R 775 /home/ \
    && /home/collectd.sh
