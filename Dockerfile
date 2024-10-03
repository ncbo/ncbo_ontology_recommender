ARG RUBY_VERSION=3.0
ARG DISTRO_NAME=bullseye

FROM ruby:$RUBY_VERSION-$DISTRO_NAME

RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends \
  openjdk-11-jre-headless \
  raptor2-utils \
  && rm -rf /var/lib/apt/lists/*

ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_BIN=/usr/local/bundle/bin \
    BUNDLE_APP_CONFIG=/usr/local/bundle/config

WORKDIR /usr/src/app

COPY Gemfile* *.gemspec ./

RUN gem update --system
RUN bundle install

COPY . .
CMD ["irb"]
