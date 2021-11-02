FROM node:alpine

WORKDIR /app
COPY package.json yarn.lock .
RUN yarn

ADD server.ts .
CMD ["node", "-r", "ts-node/register", "server.ts"]

