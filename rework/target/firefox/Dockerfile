ARG http_proxy=***********
ARG https_proxy=**********


# BROWSER LAYER
FROM selenoid/base:6.0 AS dev

ARG PACKAGE=firefox-esr
ARG VERSION=68.11.0esr+build1-0ubuntu0.18.04.1
ARG PPA=ppa:mozillateam/ppa

LABEL browser=$PACKAGE:$VERSION

# APT install
RUN  \
        rm -f /etc/apt/apt.conf.d/docker-clean && \
        apt-get update && \
        apt-get install -y software-properties-common && \
        apt-get update && \
        add-apt-repository -y $PPA && \
        apt-get update && \
        apt-get -y --no-install-recommends install iproute2 libavcodec57 $PACKAGE=$VERSION && \
        ln /usr/bin/$PACKAGE /usr/bin/firefox && \
        firefox --version && \
        rm -Rf /tmp/* && rm -Rf /var/lib/apt/lists/*



# DRIVER LAYER
FROM dev AS final
# FROM selenoid/dev_firefox:@@VERSION@@

LABEL selenoid=1.10.0
LABEL driver=geckodriver:0.24.0

# SELENOID
RUN wget -O - \
    "https://github.com/mozilla/geckodriver/releases/download/v0.24.0/geckodriver-v0.24.0-linux64.tar.gz" \
    | tar xzf - --directory /usr/bin/
RUN wget -O /usr/bin/selenoid \
    "https://github.com/aerokube/selenoid/releases/download/1.10.0/selenoid_linux_amd64" && \
    chmod +x /usr/bin/selenoid

COPY --chown=selenium:nogroup browsers.json /home/selenium/

COPY selenoid_entrypoint.sh /entrypoint.sh

USER selenium

EXPOSE 4444
ENTRYPOINT ["/entrypoint.sh"]
