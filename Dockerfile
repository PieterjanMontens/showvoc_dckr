FROM openjdk:8-jdk-buster AS common-base
LABEL maintainer="pieterjan@montens.net"

ENV sv_version=1.2.0
ENV st_version=10.2

RUN set -eux ; \
    export DEBIAN_FRONTEND=noninteractive ; \
    apt-get update ; \
    apt-get -y upgrade


# -----------------------------------------------------------------------------
# One stage to rule them
# -----------------------------------------------------------------------------
FROM common-base AS semturk
RUN curl -L https://bitbucket.org/art-uniroma2/showvoc/downloads/showvoc-${sv_version}-full.zip --output /tmp/showvoc.zip

RUN set -eux ; \
	mkdir /opt/semturk ; \
	mkdir /opt/semturk/data ; \
	cd /opt/semturk ; \
	unzip -q /tmp/showvoc.zip -d . ; \
	chmod -R u=rwX,go=rX semanticturkey-${st_version} ; \
	chmod +x semanticturkey-${st_version}/bin/* ; \
	sed -i 's/\(data\.dir\)=.*/\1=..\/data\/SemanticTurkeyData/' /opt/semturk/semanticturkey-${st_version}/etc/it.uniroma2.art.semanticturkey.cfg ; \
	rm /tmp/showvoc.zip


# -----------------------------------------------------------------------------
# One stage to find them
# -----------------------------------------------------------------------------
FROM common-base AS showvoc
RUN apt-get -y install --no-install-recommends \
        git \
        maven

RUN mkdir /opt/showvoc ; \
    git clone --depth=1 https://bitbucket.org/art-uniroma2/showvoc.git /opt/showvoc ; \
    cd /opt/showvoc ; \
    mvn clean install


# -----------------------------------------------------------------------------
# One stage to find them all,
# -----------------------------------------------------------------------------
FROM common-base as server
RUN apt-get -y install --no-install-recommends \
        nginx

# forward request and error logs to docker log collector
COPY ./nginx.config.conf /etc/nginx/sites-enabled/default


RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log


# -----------------------------------------------------------------------------
# (perhaps test them)
# -----------------------------------------------------------------------------
FROM server AS deploy-testing
COPY --from=semturk /opt/semturk /opt/semturk
COPY --from=showvoc /opt/showvoc/dist/showvoc /opt/showvoc

WORKDIR /opt/semturk/semanticturkey-$st_version
EXPOSE 80 1979

RUN apt-get -y install --no-install-recommends \
        vim-tiny

RUN echo "Start nginx server with:\n \
/etc/init.d/nginx start \
\
Start Semantik Turkey server with:\n \
bin/karaf server\
"

CMD ["bash"]

# -----------------------------------------------------------------------------
# and in a dark console bind them.
# -----------------------------------------------------------------------------
FROM server AS deploy-prod
COPY --from=semturk /opt/semturk /opt/semturk
COPY --from=showvoc /opt/showvoc/dist/showvoc /opt/showvoc

WORKDIR /opt/semturk/semanticturkey-$st_version
EXPOSE 80 1979

RUN apt-get clean ; \
    rm -rf /var/lib/apt/lists/*

RUN /etc/init.d/nginx start
ENTRYPOINT ["bin/karaf"]
CMD ["server"]
