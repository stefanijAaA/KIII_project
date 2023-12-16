FROM node:18.12.1-buster-slim

# Set to a non-root built-in user `node`
USER node

# Create app directory (with user `node`)
RUN mkdir -p /home/node

WORKDIR /home/node

# Copy needed package.json files
COPY --chown=node package.json yarn.lock ./
COPY --chown=node ./packages/config/eslint/package.json /home/node/packages/config/eslint/
COPY --chown=node ./packages/config/tsconfig/package.json /home/node/packages/config/tsconfig/

COPY --chown=node ./apps/api/package.json /home/node/apps/api/

RUN \
  yarn config set network-timeout 600000 -g && \
  yarn install --frozen-lockfile && \
  yarn cache clean

# Bundle app source code
COPY --chown=node . .

WORKDIR /home/node/apps/api/

RUN yarn build

# Bind to all network interfaces so that it can be mapped to the host OS
ARG HOST
ENV HOST=${HOST}

ARG PORT
ARG WEBSOCKET_PORT

EXPOSE ${PORT}
EXPOSE ${WEBSOCKET_PORT}

CMD [ "yarn", "start" ]