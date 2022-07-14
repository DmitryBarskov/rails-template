# frozen_string_literal: true

require "yaml"

def source_paths
  [__dir__]
end

rails_root = File.basename(destination_root)
packages = %w[bash build-base tzdata gcompat]
packages << "postgresql-dev" if defined? PG
packages << "sqlite-dev" if defined? SQLite3

file "Dockerfile", <<~DOCKERFILE
  FROM ruby:#{RUBY_VERSION}-alpine

  ARG RAILS_ROOT=/#{rails_root}
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
        ".:/#{rails_root}:cached",
        "bundle_cache:/bundle_cache"
      ],
      "ports" => ["3000:3000"],
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

if defined? PG
  db_version = ActiveRecord::Base.connection.select_value("SELECT VERSION()")[/\d+\.\d+/]

  compose_config["services"]["web"]["depends_on"] = ["db"]
  compose_config["services"]["web"]["environment"]["DATABASE_HOST"] = "db"
  compose_config["services"]["web"]["environment"]["DATABASE_USERNAME"] = "postgres"
  compose_config["services"]["web"]["environment"]["DATABASE_PASSWORD"] = "postgres"

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

  db_config = [{
    "username" => '<%= ENV["DATABASE_USERNAME"] %>',
    "password" => '<%= ENV["DATABASE_PASSWORD"] %>',
    "host" => '<%= ENV["DATABASE_HOST"] %>'
  }]

  insert_into_file "config/database.yml",
                   " #{db_config.to_yaml[5..]}",
                   after: /default: &default\n(?: +.+\n)*/
end

file "docker-compose.yml", compose_config.to_yaml[4..]

run "docker-compose build"
run "docker-compose exec web bin/rails db:prepare"
