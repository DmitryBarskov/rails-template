# frozen_string_literal: true

require "yaml"

def source_paths
  [__dir__]
end

packages = %w[bash build-base tzdata gcompat]
packages << "postgresql-dev" if defined? PG
packages << "sqlite-dev" if defined? SQLite3

file "Dockerfile", <<~DOCKERFILE
  FROM ruby:#{RUBY_VERSION}-alpine

  ARG RAILS_ROOT=/app
  ARG PACKAGES="#{packages.join(' ')}"
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

compose_config = {
  "version" => "3.7",
  "services" => {
    "web" => {
      "build" => ".",
      "volumes" => [
        ".:/app:cached",
        "bundle_cache:/bundle_cache"
      ],
      "ports" => ["3000:3000"],
      "command" => "bin/docker-entrypoint",
      "environment" => {
        "PIDFILE" => "/tmp/pids/server.pid"
      },
      "tmpfs" => [
        "/tmp/pids/"
      ]
    }
  },
  "volumes" => {
    "bundle_cache" => nil,
    "db_data" => nil
  }
}

compose_config["services"]["web"]["volumes"] << "db_data:/db" if defined? SQLite3

begin
  if defined? PG
    db_version = ENV["DB_VERSION"] || ActiveRecord::Base.connection.select_value("SELECT VERSION()")[/\d+\.\d+/]
    db_url = "postgres://postgres:postgres@db"

    compose_config["services"]["web"]["depends_on"] = ["db"]
    compose_config["services"]["web"]["environment"]["DATABASE_URL"] = db_url

    compose_config["services"]["db"] = {
      "image" => "postgres:#{db_version}-alpine",
      "volumes" => [
        "db_data:/var/lib/postgresql/data/pgdata"
      ],
      "ports" => ["5432:5432"],
      "environment" => {
        "POSTGRES_USER" => "postgres",
        "POSTGRES_PASSWORD" => "postgres",
        "PGDATA" => "/var/lib/postgresql/data/pgdata"
      }
    }

    insert_into_file "config/database.yml", "  url: #{db_url}", after: /default: &default\n(?: +.+\n)*/
  end
rescue PG::ConnectionBad
  puts "Can't connect to the database. The db service will not be installed.\nYou can specify the database version by specifying DB_VERSION=<PG version>"
end

file "docker-compose.yml", compose_config.to_yaml

copy_file "files/docker-entrypoint", "bin/docker-entrypoint"
run "chmod +x bin/docker-entrypoint"

run "docker-compose up --build"
