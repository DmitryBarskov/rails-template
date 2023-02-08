# frozen_string_literal: true

require "yaml"

def setup_ruby_steps
  [
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
end

def rspec_job
  return {} unless defined?(RSpec)

  {
    "rspec" => {
      "name" => "Tests",
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
        *setup_ruby_steps,
        {
          "name" => "Setup database",
          "run" => "bin/rails db:setup"
        },
        {
          "name" => "Run tests",
          "run" => "bin/rspec"
        }
      ]
    }
  }
end

def security_job
  return {} unless defined?(Bundler::Audit) || defined?(Brakeman)

  {
    "security" => {
      "name" => "Vulnerability scan",
      "runs-on" => "ubuntu-latest",
      "steps" => [
        *setup_ruby_steps,
        {
          "name" => "Security audit dependencies",
          "run" => "bundle exec bundler-audit --update"
        } if defined?(Bundler::Audit),
        {
          "name" => "Security audit application code",
          "run" => "bundle exec brakeman -q -w2"
        } if defined?(Brakeman)
      ].compact
    }
  }
end

def lint_job
  return {} unless defined? Rubocop

  {
    "rubocop" => {
      "name" => "Lint",
      "runs-on" => "ubuntu-latest",
      "steps" => [
        *setup_ruby_steps,
        {
          "name" => "Lint Ruby files",
          "run" => "bundle exec rubocop --parallel"
        }
      ]
    }
  }
end


actions_config = {
  "name" => "Ruby on Rails CI",
  "run-name" => "Ruby on Rails CI on ${{ github.ref_name }}",
  "on" => {
    "push" => { "branches" => %w[main] },
    "pull_request" => nil
  },
  "jobs" => {
    **rspec_job,
    **security_job,
    **rubocop_job,
  }
}

github_actions_yaml = actions_config.to_yaml

file ".github/workflows/ruby-on-rails.yml", github_actions_yaml
