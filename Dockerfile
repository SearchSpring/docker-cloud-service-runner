FROM ruby:2.1.10-alpine

RUN \
  apk add --no-cache \
  bash \
  git \
  make \
  gcc \
  alpine-sdk \
  ruby-dev

RUN \
  mkdir -p /app/docker_cloud_service_runner

COPY . /app/docker_cloud_service_runner

SHELL ["/bin/bash", "-c"]

WORKDIR /app/docker_cloud_service_runner
RUN \
  bundle install

RUN \
  rake spec && \
  rake install && \
  rake clobber

CMD ["/bin/bash"]