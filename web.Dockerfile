### Build image
FROM node:18.12.1-buster-slim AS build

WORKDIR /home/node
ENV YARN_CACHE_FOLDER=/var/yarn
ARG BACKEND_URL
ARG HUB_ID
ARG HUB_SECRET
ARG NEXTAUTH_SECRET
ARG NEXTAUTH_URL
ARG NEXT_PUBLIC_SOCKET_URL

COPY --chown=node:node package.json yarn.lock ./
COPY --chown=node:node ./packages/config/eslint/package.json /home/node/packages/config/eslint/
COPY --chown=node:node ./packages/config/tsconfig/package.json /home/node/packages/config/tsconfig/
COPY --chown=node:node ./packages/utils/package.json /home/node/packages/utils/
COPY --chown=node:node ./apps/web/package.json /home/node/apps/web/

RUN \
  apt update -qq && \
  apt install -qq -y tini && \
  apt autoremove -qq -y && \
  apt-get -qq clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/log/* && \
  yarn config set network-timeout 600000 -g && \
  yarn install --frozen-lockfile && \
  yarn cache clean

COPY ./packages /home/node/packages
COPY ./apps/web /home/node/apps/web

WORKDIR /home/node/apps/web

RUN echo "BACKEND_URL=$BACKEND_URL" > ./.env
RUN echo "NEXTAUTH_URL=$NEXTAUTH_URL" >> ./.env
RUN echo "HUB_ID=$HUB_ID" >> ./.env
RUN echo "HUB_SECRET=$HUB_SECRET" >> ./.env
RUN echo "NEXTAUTH_SECRET=$NEXTAUTH_SECRET" >> ./.env
RUN echo "NEXT_PUBLIC_SOCKET_URL=$NEXT_PUBLIC_SOCKET_URL" >> ./.env

RUN yarn build

### Final image, install production dependencies and do some cleanup
FROM node:18.12.1-buster-slim AS production
WORKDIR /home/node
RUN \
  apt update -qq && \
  apt upgrade -y bash && \
  apt install -qq -y tini && \
  rm -rf /var/lib/apt/lists/*

ENV YARN_CACHE_FOLDER=/var/yarn
ENV NODE_ENV=production

COPY --from=build --chown=node:node /home/node/packages/ ./packages
COPY --from=build --chown=node:node /home/node/apps/ ./apps
COPY --from=build --chown=node:node /home/node/apps/web/.next ./.next
COPY --from=build --chown=node:node /home/node/apps/web/public ./public
COPY --chown=node:node /entrypoint.sh .

ARG BACKEND_URL
ARG HUB_ID
ARG HUB_SECRET
ARG NEXTAUTH_SECRET
ARG NEXTAUTH_URL
ARG NEXT_PUBLIC_SOCKET_URL

# TODO: We need to send real env vars to the container
RUN echo "BACKEND_URL=$BACKEND_URL" > ./.env.production
RUN echo "NEXTAUTH_URL=$NEXTAUTH_URL" >> ./.env.production
RUN echo "HUB_ID=$HUB_ID" >> ./.env.production
RUN echo "HUB_SECRET=$HUB_SECRET" >> ./.env.production
RUN echo "NEXTAUTH_SECRET=$NEXTAUTH_SECRET" >> ./.env.production
RUN echo "NEXT_PUBLIC_SOCKET_URL=$NEXT_PUBLIC_SOCKET_URL" >> ./.env.production

RUN \
  yarn config set network-timeout 600000 -g && \
  yarn install --production && \
  yarn cache clean

COPY --from=build --chown=node:node /home/node/node_modules ./node_modules

USER node
EXPOSE 3000

RUN ["chmod", "+x", "./entrypoint.sh"]
ENTRYPOINT ["./entrypoint.sh"]

# This runs tini as the init system, which will pass signals (HUP etc) to pid 1
# ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["apps/web/node_modules/.bin/next", "start"]
