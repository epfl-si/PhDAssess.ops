ARG BASE_IMAGE=node:alpine

FROM $BASE_IMAGE

WORKDIR /app
COPY package.json yarn.lock ./
RUN yarn

ADD server.ts .
CMD ["node", "-r", "ts-node/register", "server.ts"]
