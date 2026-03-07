ARG DISTRO_RELEASE=ubuntu:jammy
FROM $DISTRO_RELEASE

ARG APT_MIRROR=mirrors.wikimedia.org
RUN perl -pi \
    -e 's,deb.debian.org/(debian)(?!-sec),<APT>/$1,;' \
    -e 's!deb.debian.org/(debian-security)!<APT>/$1! if 0;' \
    -e 's!archive.ubuntu.com/(ubuntu)!<APT>/$1!;' \
    -e 's!security.ubuntu.com/(ubuntu)!<APT>/$1-security! if 0;' \
    -e 's!ports.ubuntu.com/(ubuntu-ports)!<APT>/$1!;' \
    -e "s!<APT>!$APT_MIRROR!;" \
    -e 's!^# (deb-src) !$1 !;' \
    -e 's!^(Types: deb)$!$1 deb-src!' \
    /etc/apt/sources.list \
    /etc/apt/sources.list.d/*.sources

RUN apt-get update && apt-get -y install whiptail \
    && DEBIAN_FRONTEND=noninteractive apt-get -y install \
    apt-utils \
    ccache \
    cdbs \
    debian-archive-keyring \
    debian-keyring \
    debian-ports-archive-keyring \
    devscripts \
    dpkg-dev \
    equivs \
    git \
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
    tree \
    tzdata \
    wget

RUN perl -pi -e 's/^#?(DIR_MODE)=.*/$1=755/' /etc/adduser.conf \
    && adduser \
    --uid 1024 \
    --ingroup users \
    --gecos 'Build User,,,' \
    --disabled-password \
    build

RUN --mount=type=bind,source=.,target=/mnt /mnt/setup.sh

ENV LANG=C.UTF-8 LC_COLLATE=C SHELL=/bin/bash

CMD exec ${SHELL} -l

# EOF
