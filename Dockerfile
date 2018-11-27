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
ARG METABASE_VERSION=v0.31.1

# Specify PR ids to pull and apply to source code
ARG METABASE_PULLS=9022

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
    
COPY --from=builder /app/source/metabase/target/uberjar/metabase.jar /app/target/uberjar/
COPY --from=builder /app/source/metabase/bin/start /app/bin/

EXPOSE 3000

ENTRYPOINT ["/app/bin/start"]
