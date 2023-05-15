# This is the dev-only Dockerfile used trough ../docker-compose.yml
FROM camunda/zeebe:8.2.4

ADD https://github.com/camunda-community-hub/zeebe-hazelcast-exporter/releases/download/1.4.0/zeebe-hazelcast-exporter-1.4.0-jar-with-dependencies.jar /usr/local/zeebe/lib/zeebe-hazelcast-exporter.jar

RUN chmod 755 /usr/local/zeebe/lib/*jar
