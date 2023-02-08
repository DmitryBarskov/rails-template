# frozen_string_literal: true

require "yaml"

def gem_installed?(gem_name)
  require gem_name

  true
rescue LoadError
  false
end

def setup_ruby_steps
  [
    {
      "name" => "Checkout code",
      "uses" => "actions/checkout@v2"
    },
    {
      "name" => "Install Ruby and gems",
      "uses" => "ruby/setup-ruby@v1",
      "with" => { "bundler-cache" => true }
    }
  ]
end

def rspec_job
  return {} unless gem_installed?('rspec') || gem_installed?('rspec-rails')

  {
    "rspec" => {
      "name" => "Tests",
      "runs-on" => "ubuntu-latest",
      "services" => {
        "postgres" => {
          "image" => "postgres:11-alpine",
          "ports" => ["5432:5432"],
          "env" => {
            "POSTGRES_DB" => "#{app_name}_test",
            "POSTGRES_USER" => "actions",
            "POSTGRES_PASSWORD" => "password"
          }
        }
      },
      "env" => {
        "RAILS_ENV" => "test",
        "DATABASE_HOST" => "localhost",
        "DATABASE_PORT" => 5432,
        "DATABASE_URL" => "postgres://actions:password@localhost:5432/#{app_name}_test"
      },
      "steps" => [
        *setup_ruby_steps,
        {
          "name" => "Setup database",
          "run" => "bin/rails db:setup"
        },
        {
          "name" => "Run tests",
          "run" => "bundle exec rspec"
        }
      ]
    }
  }
end

def security_job
  return {} unless gem_installed?('bundler/audit') || gem_installed?('brakeman')

  {
    "security" => {
      "name" => "Vulnerability scan",
      "runs-on" => "ubuntu-latest",
      "steps" => [
        *setup_ruby_steps,
        if gem_installed?('bundler/audit')
          {
            "name" => "Security audit dependencies",
            "run" => "bundle exec bundler-audit --update"
          }
        end,
        if gem_installed?('brakeman')
          {
            "name" => "Security audit application code",
            "run" => "bundle exec brakeman -q -w2"
          }
        end
      ].compact
    }
  }
end

def rubocop_job
  return {} unless gem_installed?('rubocop')

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
bundle_command "lock --add-platform x86_64-linux"
