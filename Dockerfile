FROM registry.access.redhat.com/hi/nginx:latest

ARG SITE_VERSION
ARG LATEST_K8S_VERSION

COPY site/ /usr/share/nginx/html/
COPY nginx.conf /etc/nginx/nginx.conf

RUN sed -i "s|__LATEST_K8S_VERSION__|${LATEST_K8S_VERSION}|g" /etc/nginx/nginx.conf

LABEL org.opencontainers.image.version="${SITE_VERSION}" \
      org.opencontainers.image.source="https://github.com/kubernetools/deploy"

EXPOSE 8080
