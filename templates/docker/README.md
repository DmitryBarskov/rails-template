# docker-rails-template
Adds Dockerfile and docker-compose to Ruby on Rails application.

Usage:
```bash
bin/rails app:template LOCATION=https://raw.githubusercontent.com/DmitryBarskov/rails-template/main/templates/docker/base.rb

# To specify database version if you are using PostgreSQL
bin/rails app:template LOCATION=https://raw.githubusercontent.com/DmitryBarskov/rails-template/main/templates/docker/base.rb DB_VERSION=<PG version>
```
