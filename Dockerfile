FROM java:openjdk-7-jre-alpine

ENV JAVA_HOME=/usr/lib/jvm/default-jvm
ENV PATH /usr/local/bin:$PATH
ENV LEIN_ROOT 1
ENV FC_LANG en-US
ENV LC_CTYPE en_US.UTF-8

# install core build tools
RUN apk add --update nodejs git wget bash python make g++ java-cacerts ttf-dejavu fontconfig curl procps && \
	npm install -g yarn && \
	ln -sf "${JAVA_HOME}/bin/"* "/usr/bin/" && \
	rm -f /usr/lib/jvm/default-jvm/jre/lib/security/cacerts && \
	ln -s /etc/ssl/certs/java/cacerts /usr/lib/jvm/default-jvm/jre/lib/security/cacerts && \
	curl -o /usr/local/bin/lein https://raw.github.com/technomancy/leiningen/stable/bin/lein && \
	chmod 744 /usr/local/bin/lein && \
	mkdir -p /app/source && \
	git clone https://github.com/huksley/metabase /app/source && \
	cd /app/source && \
	bin/build && \
	apk del nodejs git wget python make g++ && \
	rm -rf /root/.lein /root/.m2 /root/.node-gyp /root/.npm /root/.yarn /root/.yarn-cache \
		/tmp/* /var/cache/apk/* /app/source/node_modules \
		/usr/local/share/.cache && \
	find / 

# expose our default runtime port
EXPOSE 3000

# build and then run it
WORKDIR /app/source
ENTRYPOINT ["./bin/start"]
