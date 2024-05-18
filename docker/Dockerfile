ARG DISTRO_RELEASE=ubuntu:jammy
FROM $DISTRO_RELEASE

# https://bugs.debian.org/1054104
ARG QEMU_BINFMT=dummy
ADD $QEMU_BINFMT /usr/libexec/qemu-binfmt/

ARG APT_MIRROR=mirrors.wikimedia.org
RUN perl -pi \
    -e 's,deb.debian.org/(debian)(?!-sec),<APT>/$1,;' \
    -e 's!deb.debian.org/(debian-security)!<APT>/$1! if 0;' \
    -e 's!archive.ubuntu.com/(ubuntu)!<APT>/$1!;' \
    -e 's!security.ubuntu.com/(ubuntu)!<APT>/$1-security! if 0;' \
    -e 's!ports.ubuntu.com/(ubuntu-ports)!<APT>/$1!;' \
    -e "s!<APT>!$APT_MIRROR!" \
    /etc/apt/sources.list \
    /etc/apt/sources.list.d/*.sources

RUN apt-get update && apt-get -y install whiptail \
    && DEBIAN_FRONTEND=noninteractive apt-get -y install \
    ccache \
    cdbs \
    debian-keyring \
    devscripts \
    dpkg-dev \
    equivs \
    less \
    nano \
    netcat-openbsd \
    pigz \
    pixz \
    procps \
    psmisc \
    quilt \
    rsync \
    time \
    tzdata \
    wget

ADD hybrid-amd64-setup.sh hybrid-match-versions.sh /tmp/
RUN /tmp/hybrid-amd64-setup.sh && rm /tmp/hybrid-*.sh

RUN perl -pi -e 's/^#?(DIR_MODE)=.*/$1=755/' /etc/adduser.conf \
    && adduser \
    --uid 1024 \
    --ingroup users \
    --gecos 'Build User,,,' \
    --disabled-password \
    build

RUN test -f /etc/ccache.conf && exit 1; \
    (echo 'cache_dir = /external/ccache'; \
     echo 'compiler_check = %compiler% -v'; \
     echo 'inode_cache = false'; \
     echo 'max_size = 20G'; \
     echo 'sloppiness = include_file_ctime, include_file_mtime, locale, time_macros'; \
     echo 'temporary_dir = /external/tmp') > /etc/ccache.conf

ENV LANG=C.UTF-8 LC_COLLATE=C SHELL=/bin/bash

CMD exec ${SHELL} -l

# EOF
