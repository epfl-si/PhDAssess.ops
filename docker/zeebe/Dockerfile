ARG BASE_IMAGE=camunda/zeebe:8.5.17

FROM $BASE_IMAGE

ADD https://github.com/camunda-community-hub/zeebe-hazelcast-exporter/releases/download/1.4.0/zeebe-hazelcast-exporter-1.4.0-jar-with-dependencies.jar /usr/local/zeebe/lib/zeebe-hazelcast-exporter.jar

USER root

RUN chmod 755 /usr/local/zeebe/lib/*jar

USER 1001:1001
