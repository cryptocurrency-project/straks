FROM ubuntu:18.04

MAINTAINER Yuki Watanabe <watanabe@future-needs.com>

ARG USER_ID
ARG GROUP_ID

ENV HOME /straks

# add user with specified (or default) user/group ids
ENV USER_ID ${USER_ID:-1000}
ENV GROUP_ID ${GROUP_ID:-1000}

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -g ${GROUP_ID} straks \
	&& useradd -u ${USER_ID} -g straks -s /bin/bash -m -d /straks straks

ARG STRAKS_VERSION=${STRAKS_VERSION:-1.14.7.5}
ENV STRAKS_PREFIX=/opt/straks-${STRAKS_VERSION}
ENV STRAKS_DATA=/straks/.straks
ENV PATH=/straks/straks-${STRAKS_VERSION}/bin:$PATH

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN set -xe \
        && apt-get update \
        && apt-get install -y \
        build-essential \
        libtool autotools-dev autoconf automake \
        libssl-dev \
        libboost-all-dev \
        pkg-config \
        software-properties-common git \
        && add-apt-repository -y ppa:bitcoin/bitcoin \
        && apt-get -y update \
        && apt-get install -y \
        libdb4.8-dev libdb4.8++-dev \
        libminiupnpc-dev \
        libqt4-dev libprotobuf-dev protobuf-compiler \
        libqt5gui5 libqt5core5a libqt5dbus5 qttools5-dev qttools5-dev-tools libprotobuf-dev \
        libcanberra-gtk-module \
        gtk2-engines-murrine \
        libqrencode-dev \
        libevent-dev \
        libzmq3-dev \
        wget \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# add universe repo if not enabled already
RUN set -xe \
        && apt-add-repository universe \
        && add-apt-repository ppa:straks/straks \
        && apt-get update \
        && apt-get install straksd

# grab gosu for easy step-down from root
ARG GOSU_VERSION=${GOSU_VERSION:-1.11}
RUN set -xe \
	&& apt-get update && apt-get install -y --no-install-recommends \
		ca-certificates \
		wget \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
	&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu \
	&& gosu nobody true \
	&& apt-get purge -y \
		ca-certificates \
		wget \
	&& apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD ./bin /usr/local/bin

VOLUME ["/straks"]

EXPOSE 7575 7574 17575 17574

WORKDIR /straks

COPY docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["straks_oneshot"]
