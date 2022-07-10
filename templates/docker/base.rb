# frozen_string_literal: true

def source_paths
  [__dir__]
end

copy_file(
  "files/Dockerfile",
  "Dockerfile"
)

rails_root = File.basename(destination_root)
ruby_version = File.readlines(".ruby-version", chomp: true).first if File.exist?(".ruby-version")
ruby_version ||= "3.1.1"
bundler_version = File.readlines("Gemfile.lock", chomp: true).last.strip
packages = %w[bash build-base tzdata gcompat]
packages << "postgresql-dev" if defined? PG
packages << "sqlite-dev" if defined? SQLite3

gsub_file "Dockerfile", "{$RUBY_VERSION}", ruby_version
gsub_file "Dockerfile", "{$BUNDLER_VERSION}", bundler_version
gsub_file "Dockerfile", "{$RAILS_ROOT}", rails_root
gsub_file "Dockerfile", "{$PACKAGES}", packages.join(" ")

if defined? PG
  copy_file(
    "files/docker-compose.yml",
    "docker-compose.yml"
  )
  gsub_file "docker-compose.yml", "{$RAILS_ROOT}", rails_root

  db_version = ActiveRecord::Base.connection.select_value("SELECT VERSION()")[/\d+\.\d+/]
  db_username = "postgres"
  db_password = "postgres"
  db_image = "postgres:#{db_version}-alpine"
  db_volume = "var/lib/postgresql/data/pgdata"
  db_ports = "5432:5432"
  db_env = <<~YAML
    POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          PGDATA: /var/lib/postgresql/data/pgdata
  YAML
  insert_into_file "config/database.yml", before: "\ndevelopment:" do
    <<~YAML
      \s\susername: <%= ENV["DATABASE_USERNAME"] %>
      \s\spassword: <%= ENV["DATABASE_PASSWORD"] %>
      \s\shost: <%= ENV["DATABASE_HOST"] %>
    YAML
  end

  gsub_file "docker-compose.yml", "{$DB_USERNAME}", db_username
  gsub_file "docker-compose.yml", "{$DB_PASSWORD}", db_password
  gsub_file "docker-compose.yml", "{$DB_IMAGE}", db_image
  gsub_file "docker-compose.yml", "{$DB_VOLUME}", db_volume
  gsub_file "docker-compose.yml", "{$DB_PORTS}", db_ports
  gsub_file "docker-compose.yml", "{$DB_ENV}", db_env
end
if defined? SQLite3
  copy_file(
    "files/docker-compose-sqlite.yml",
    "docker-compose.yml"
  )
  gsub_file "docker-compose.yml", "{$RAILS_ROOT}", rails_root
end

run "docker-compose build"
run "docker-compose exec web bin/rails db:prepare"
