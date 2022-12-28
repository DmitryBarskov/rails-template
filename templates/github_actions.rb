# frozen_string_literal: true

require "yaml"

required_steps = [
  {
    "name" => "Checkout code",
    "uses" => "actions/checkout@v2"
  },
  {
    "name" => "Install Ruby and gems",
    "uses" => "ruby/setup-ruby@1.99.0",
    "with" => { "bundler-cache" => true }
  }
]

actions_config = {
  "name" => "Ruby on Rails CI",
  "run-name" => "Ruby on Rails CI on ${{ github.ref_name }}",
  "on" => ["push"],
  "jobs" => {
    "test" => {
      "runs-on" => "ubuntu-latest",
      "services" => {
        "postgres" => {
          "image" => "postgres:11-alpine",
          "ports" => ["5432:5432"],
          "env" => {
            "POSTGRES_DB" => "test_db",
            "POSTGRES_USER" => "actions",
            "POSTGRES_PASSWORD" => "password"
          }
        }
      },
      "env" => {
        "RAILS_ENV" => "test",
        "DATABASE_URL" => "postgres://actions:password@localhost:5432/test_db"
      },
      "steps" => [
        *required_steps,
        {
          "name" => "Setup database",
          "run" => "bin/rails db:setup"
        },
        {
          "name" => "Run tests",
          "run" => "bin/rspec"
        }
      ]
    },
    "lint" => {
      "runs-on" => "ubuntu-latest",
      "steps" => [
        *required_steps,
        {
          "name" => "Security audit dependencies",
          "run" => "bin/bundler-audit --update"
        },
        {
          "name" => "Security audit application code",
          "run" => "bin/brakeman -q -w2"
        },
        {
          "name" => "Lint Ruby files",
          "run" => "bin/rubocop --parallel"
        }
      ]
    }
  }
}

github_actions_yaml = actions_config.to_yaml

file ".github/workflows/ruby-on-rails.yml", github_actions_yaml
