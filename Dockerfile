#
# Based on original https://github.com/metabase/metabase/blob/master/Dockerfile
#
FROM openjdk:8-jdk-alpine as builder
WORKDIR /app/source
ENV JAVA_HOME=/usr/lib/jvm/default-jvm
ENV PATH /usr/local/bin:$PATH
ENV FC_LANG en-US
ENV LC_CTYPE en_US.UTF-8

# Specify version here or on docker build line
ARG METABASE_VERSION=v0.33.0-RC1

# Specify PR ids to pull and apply to source code
ARG METABASE_PULLS=

ADD https://raw.github.com/technomancy/leiningen/stable/bin/lein /usr/local/bin/lein
ADD https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem /tmp/rds-combined-ca-bundle.pem
ADD apply-pulls /app/source/

# Install software, add all AWS/RDS certificates
RUN apk add --update --no-cache wget bash curl patch java-cacerts ttf-dejavu fontconfig git make gettext bash yarn && \
    keytool -noprompt -import -trustcacerts -alias aws-rds \
      -file /tmp/rds-combined-ca-bundle.pem \
      -keystore /etc/ssl/certs/java/cacerts \
      -keypass changeit -storepass changeit && \
    chmod 744 /usr/local/bin/lein && \
    lein upgrade && \
    true

RUN git clone --branch $METABASE_VERSION --depth 1 https://github.com/metabase/metabase && \
    cd metabase && \
    git checkout tags/$METABASE_VERSION && \
    /app/source/apply-pulls && \
    lein deps && \
    yarn && \
    bin/build && \
    cp /app/source/metabase/target/uberjar/metabase.jar /app/source/metabase.jar && \
    lein install-for-building-drivers && \
    cd .. && \
    true

RUN git clone --depth 1 https://github.com/tlrobinson/metabase-http-driver && \
    cd metabase-http-driver && \
    lein clean && \
    DEBUG=1 LEIN_SNAPSHOTS_IN_RELEASE=true lein uberjar && \
    true

FROM openjdk:8-jre-alpine as runner
WORKDIR /app
ENV JAVA_HOME=/usr/lib/jvm/default-jvm
ENV PATH /usr/local/bin:$PATH
ENV FC_LANG en-US
ENV LC_CTYPE en_US.UTF-8

COPY --from=builder /etc/ssl/certs/java/cacerts /usr/lib/jvm/default-jvm/jre/lib/security/cacerts

RUN apk add --update --no-cache bash && \
    mkdir -p bin target/uberjar
    
COPY --from=builder /app/source/metabase.jar /app/target/uberjar/
COPY --from=builder /app/source/metabase-http-driver/target/uberjar/http.metabase-driver.jar /app/target/plugins/
COPY --from=builder /app/source/metabase/bin/start /app/bin/

EXPOSE 3000

ENTRYPOINT ["/app/bin/start"]
