FROM debian/eol:wheezy
MAINTAINER Valerio Di Giampietro "valerio@digiampietro.com"
#
# increase the version to force recompilation of everything
#
ENV BUILDROOT_MIPS4KC 0.8.3
#
# ------------------------------------------------------------------
# environment variables to avoid that dpkg-reconfigure 
# tries to ask the user any questions
#
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true
#
# ----------------------------------------------------------------- 
# install needed packages to build and run buildroot and related sw
#
RUN apt-get update

RUN apt-get upgrade

RUN apt-get install -y -q \
    bash \
    bc \
    binutils \
    build-essential \
    bzip2 \
    ca-certificates \
    cpio \
    debianutils \
    g++ \
    gcc \
    gzip \
    libncurses5-dev \
    locales \
    make \
    patch \
    perl \
    python \
    rsync \
    sed \
    tar \
    unzip \
    wget \
    git \
    fakeroot \
    login \
    libqt4-dev \
    pkg-config \
    libqt4-dev-bin

RUN sed -i "s/^# en_US.UTF-8/en_US.UTF-8/" /etc/locale.gen && locale-gen && update-locale LANG=en_US.UTF-8
#
# prepare startup files in /src/misc
#
RUN mkdir -p      /src/misc
ADD startup.sh    /src/misc/startup.sh
RUN chmod a+x     /src/misc/startup.sh
ENTRYPOINT cd     /src/misc ; ./startup.sh
