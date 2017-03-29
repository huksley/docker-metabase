FROM java:openjdk-7-jre-alpine

ENV JAVA_HOME=/usr/lib/jvm/default-jvm
ENV PATH /usr/local/bin:$PATH

RUN mkdir -p /app/source/target/uberjar && mkdir -p /app/source/bin
COPY start /app/source/bin
COPY metabase.jar /app/source/target/uberjar
RUN chmod a+x /app/source/bin/start

EXPOSE 3000
WORKDIR /app/source
ENTRYPOINT ["./bin/start"]
