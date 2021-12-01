FROM ghcr.io/camunda-community-hub/zeebe-simple-monitor:2.1.0

ADD postgresql-42.2.12.jar /app/libs/postgresql-42.2.12.jar
RUN echo ":/app/libs/postgresql-42.2.12.jar" >> /app/jib-classpath-file
ADD application.yaml /application.yaml
