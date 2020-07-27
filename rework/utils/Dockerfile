FROM selenoid/base:6.0

ARG http_proxy
ARG https_proxy

ENV http_proxy=$http_proxy
ENV https_proxy=$https_proxy

RUN apt-get update && \
	apt-get install -y python3-pip && \
	pip3 install j2cli && \
	j2 --version

WORKDIR /tmp

# j2 Dockerfile.j2 $conf_file > Dockerfile
