FROM ruby:{$RUBY_VERSION}-alpine

ARG RAILS_ROOT=/{$RAILS_ROOT}
ARG PACKAGES="{$PACKAGES}"
ARG BUNDLER_VERSION="{$BUNDLER_VERSION}"
ENV BUNDLE_PATH="/bundle_cache"
ENV GEM_HOME="/bundle_cache"
ENV GEM_PATH="/bundle_cache"

RUN apk update \
 && apk upgrade \
 && apk add --update --no-cache $PACKAGES

WORKDIR $RAILS_ROOT

RUN gem install bundler:$BUNDLER_VERSION
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 5

ADD . $RAILS_ROOT
ENV PATH=$RAILS_ROOT/bin:${PATH}

EXPOSE 3000
CMD bundle exec rails server -b 0.0.0.0
