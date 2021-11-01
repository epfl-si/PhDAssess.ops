FROM camunda/zeebe:1.2.2

# Inferred from https://github.com/camunda-community-hub/zeebe-simple-monitor/blob/master/docker/docker-compose.yml
ADD zeebe-hazelcast-exporter-1.0.0-jar-with-dependencies.jar /usr/local/zeebe/exporters/zeebe-hazelcast-exporter.jar
ADD application.yaml /usr/local/zeebe/config/application.yaml
