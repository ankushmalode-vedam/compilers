# Check for latest version here: https://hub.docker.com/_/buildpack-deps?tab=tags&page=1&name=buster&ordering=last_updated
# This is just a snapshot of buildpack-deps:buster that was last updated on 2019-12-28.
#FROM judge0/buildpack-deps:buster-2019-12-28
FROM buildpack-deps:latest

# Check for latest version here: https://gcc.gnu.org/releases.html, https://ftpmirror.gnu.org/gcc
# ENV GCC_VERSIONS \
#       7.4.0 \
#       8.3.0 \
#       9.2.0

ENV GCC_VERSIONS 13.3.0

RUN set -xe && \
    for VERSION in $GCC_VERSIONS; do \
      curl -fSsL "https://ftpmirror.gnu.org/gcc/gcc-$VERSION/gcc-$VERSION.tar.gz" -o /tmp/gcc-$VERSION.tar.gz && \
      mkdir /tmp/gcc-$VERSION && \
      tar -xf /tmp/gcc-$VERSION.tar.gz -C /tmp/gcc-$VERSION --strip-components=1 && \
      rm /tmp/gcc-$VERSION.tar.gz && \
      cd /tmp/gcc-$VERSION && \
      ./contrib/download_prerequisites && \
      { rm *.tar.* || true; } && \
      tmpdir="$(mktemp -d)" && \
      cd "$tmpdir"; \
      if [ $VERSION = "13.3.0" ]; then \
        ENABLE_FORTRAN=",fortran"; \
      else \
        ENABLE_FORTRAN=""; \
      fi; \
      /tmp/gcc-$VERSION/configure \
        --disable-multilib \
        --enable-languages=c,c++$ENABLE_FORTRAN \
        --prefix=/usr/local/gcc-$VERSION && \
      make -j$(nproc) && \
      make -j$(nproc) install-strip && \
      rm -rf /tmp/*; \
    done

# Check for latest version here: https://www.ruby-lang.org/en/downloads
#ENV RUBY_VERSIONS \
#    2.7.0 \
#    2.7.8 \
#    3.1.6
ENV RUBY_VERSIONS 3.3.8

RUN set -xe && \
    for VERSION in $RUBY_VERSIONS; do \
      curl -fSsL "https://cache.ruby-lang.org/pub/ruby/${VERSION%.*}/ruby-$VERSION.tar.gz" -o /tmp/ruby-$VERSION.tar.gz && \
      mkdir /tmp/ruby-$VERSION && \
      tar -xf /tmp/ruby-$VERSION.tar.gz -C /tmp/ruby-$VERSION --strip-components=1 && \
      rm /tmp/ruby-$VERSION.tar.gz && \
      cd /tmp/ruby-$VERSION && \
      ./configure \
        --disable-install-doc \
        --prefix=/usr/local/ruby-$VERSION && \
      make -j$(nproc) && \
      make -j$(nproc) install && \
      rm -rf /tmp/*; \
    done

# Check for latest version here: https://www.python.org/downloads
# ENV PYTHON_VERSIONS \
#       3.8.1
ENV PYTHON_VERSIONS 3.12.11

RUN set -xe && \
    for VERSION in $PYTHON_VERSIONS; do \
      curl -fSsL "https://www.python.org/ftp/python/$VERSION/Python-$VERSION.tar.xz" -o /tmp/python-$VERSION.tar.xz && \
      mkdir /tmp/python-$VERSION && \
      tar -xf /tmp/python-$VERSION.tar.xz -C /tmp/python-$VERSION --strip-components=1 && \
      rm /tmp/python-$VERSION.tar.xz && \
      cd /tmp/python-$VERSION && \
      ./configure \
        --prefix=/usr/local/python-$VERSION && \
      make -j$(nproc) && \
      make -j$(nproc) install && \
      rm -rf /tmp/*; \
    done

# Check for latest version here: https://ftpmirror.gnu.org/bash
# ENV BASH_VERSIONS \
#       5.0
ENV BASH_VERSIONS 5.3

RUN set -xe && \
    for VERSION in $BASH_VERSIONS; do \
      curl -fSsL "https://ftpmirror.gnu.org/bash/bash-$VERSION.tar.gz" -o /tmp/bash-$VERSION.tar.gz && \
      mkdir /tmp/bash-$VERSION && \
      tar -xf /tmp/bash-$VERSION.tar.gz -C /tmp/bash-$VERSION --strip-components=1 && \
      rm /tmp/bash-$VERSION.tar.gz && \
      cd /tmp/bash-$VERSION && \
      ./configure \
        --prefix=/usr/local/bash-$VERSION && \
      make -j$(nproc) && \
      make -j$(nproc) install && \
      rm -rf /tmp/*; \
    done

# Check for latest version here: https://packages.debian.org/buster/clang-7
# Used for additional compilers for C, C++ and used for Objective-C.
RUN set -xe && \
    apt-get update && \
    # apt-get install -y --no-install-recommends clang-7 gnustep-devel && \
    apt-get install -y clang gnustep-devel && \
    rm -rf /var/lib/apt/lists/*

RUN set -xe && \
    apt-get update && \
    apt-get install -y --no-install-recommends locales && \
    rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

RUN set -xe && \
    apt-get update && \
    # Install necessary packages for isolate and its dependencies
    apt-get install -y --no-install-recommends git build-essential pkg-config libcap-dev libseccomp-dev libsystemd-dev ca-certificates && \
    # Clean up apt cache immediately to save layer space
    rm -rf /var/lib/apt/lists/* && \
    git clone https://github.com/ioi/isolate.git /tmp/isolate && \
    cd /tmp/isolate && \
    git checkout v2.4 && \
    make clean && \
    make -j"$(nproc)" install

# add user & security feature in Linux used to run rootless containers or sandboxes safely
RUN set -xe && \
    useradd -r -s /usr/sbin/nologin isolate && \
    echo "isolate:100000:65536" > /etc/subuid && \
    echo "ubuntu:165536:65536" >> /etc/subuid && \
    echo "isolate:100000:65536" > /etc/subgid && \
    echo "ubuntu:165536:65536" >> /etc/subgid && \
    cat /etc/subuid && \
    cat /etc/subgid

#Create lock and box directories
RUN set -xe && \
    mkdir -p /run/isolate/locks && \
    mkdir -p /var/local/lib/isolate && \
    sed -i 's|cg_root = auto:/run/isolate/cgroup|cg_root = /sys/fs/cgroup|' /usr/local/etc/isolate
ENV BOX_ROOT /var/local/lib/isolate

LABEL maintainer="Herman Zvonimir Došilović <hermanz.dosilovic@gmail.com>"
LABEL version="1.4.0"
