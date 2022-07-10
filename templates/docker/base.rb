# frozen_string_literal: true

def source_paths
  [__dir__]
end

rails_root = File.basename(destination_root)

file "Dockerfile", <<~DOCKERFILE
  FROM ruby:#{RUBY_VERSION}-alpine

  ARG RAILS_ROOT=/#{rails_root}
  ARG PACKAGES="bash build-base tzdata gcompat #{'postgresql-dev' if defined? PG}#{'sqlite-dev' if defined? SQLite3}"
  ARG BUNDLER_VERSION="#{Bundler::VERSION}"
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
DOCKERFILE

if defined? SQLite3
  file "docker-compose.yml", <<~YAML
    version: "3.7"

    services:
      web:
        build: .
        volumes:
          - .:/#{rails_root}:cached
          - bundle_cache:/bundle_cache
          - db_data:/db
        ports:
          - 3000:3000
        environment:
          PIDFILE: /tmp/pids/server.pid
        tmpfs:
          - /tmp/pids/

    volumes:
      bundle_cache:
      db_data:
  YAML
end
if defined? PG
  db_version = ActiveRecord::Base.connection.select_value("SELECT VERSION()")[/\d+\.\d+/]

  file "docker-compose.yml", <<~YAML
    version: "3.7"

    services:
      web:
        build: .
        volumes:
          - .:/#{rails_root}:cached
          - bundle_cache:/bundle_cache
        ports:
          - 3000:3000
        depends_on:
          - db
        environment:
          DATABASE_HOST: db
          DATABASE_USERNAME: postgres
          DATABASE_PASSWORD: postgres
          PIDFILE: /tmp/pids/server.pid
        tmpfs:
          - /tmp/pids/

      db:
        image: postgres:#{db_version}-alpine
        volumes:
          - db_data:/var/lib/postgresql/data/pgdata
        ports:
          - 5432:5432
        environment:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          PGDATA: /var/lib/postgresql/data/pgdata
    volumes:
      bundle_cache:
      db_data:
  YAML

  insert_into_file "config/database.yml", before: "\ndevelopment:" do
    <<~YAML
      \s\susername: <%= ENV["DATABASE_USERNAME"] %>
      \s\spassword: <%= ENV["DATABASE_PASSWORD"] %>
      \s\shost: <%= ENV["DATABASE_HOST"] %>
    YAML
  end
end

run "docker-compose build"
run "docker-compose exec web bin/rails db:prepare"
