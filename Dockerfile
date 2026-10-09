# syntax=docker/dockerfile:1.7

FROM node:24-alpine AS build

WORKDIR /app

COPY package*.json ./
RUN --mount=type=cache,target=/root/.npm \
  npm ci

COPY . .
RUN npm run build

FROM nginx:1.29-alpine

LABEL org.opencontainers.image.source="https://github.com/paulbailey-homelab/righttrain-web"

RUN mkdir -p /tmp/nginx/client_temp /tmp/nginx/proxy_temp /tmp/nginx/fastcgi_temp /tmp/nginx/uwsgi_temp /tmp/nginx/scgi_temp

COPY nginx.conf /etc/nginx/nginx.conf
COPY --from=build /app/dist /usr/share/nginx/html
COPY docker-entrypoint.d/40-runtime-config.sh /docker-entrypoint.d/40-runtime-config.sh

RUN chmod +x /docker-entrypoint.d/40-runtime-config.sh \
  && chown -R 100:101 /tmp/nginx /usr/share/nginx/html /etc/nginx /docker-entrypoint.d
