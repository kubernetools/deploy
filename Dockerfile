FROM registry.access.redhat.com/hi/nginx:latest

ARG SITE_VERSION

COPY site/ /usr/share/nginx/html/
COPY nginx.conf /etc/nginx/nginx.conf

LABEL org.opencontainers.image.version="${SITE_VERSION}" \
      org.opencontainers.image.source="https://github.com/kubernetools/deploy"

EXPOSE 8080
