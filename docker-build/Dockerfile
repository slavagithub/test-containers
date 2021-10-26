FROM openjdk:8-jre
ENV HZ_HOME /opt/hazelcast/
RUN mkdir -p $HZ_HOME
WORKDIR $HZ_HOME

ADD test-containers-*.jar $HZ_HOME

ADD server.sh /$HZ_HOME/server.sh
RUN chmod +x /$HZ_HOME/server.sh
# Start data loader
CMD ["./server.sh"]
