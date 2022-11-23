# frozen_string_literal: true

require "yaml"

def gem_installed?(gem_name)
  Gem::Specification.find_by_name(gem_name)
rescue Gem::LoadError
  nil
end

semaphore_config = {
  "version" => "v1.0",
  "name" => "Ruby on Rails CI",
  "agent" => {
    "machine" => {
      "type" => "e1-standard-2",
      "os_image" => "ubuntu2004"
    }
  },
  "execution_time_limit" => {
    "minutes" => 10
  },
  "auto_cancel" => {
    "running" => {
      "when" => true
    }
  },
  "fail_fast" => {
    "stop" => {
      "when" => true
    }
  },
  "global_job_config" => {
    "prologue" => {
      "commands" => [
        "checkout",
        "cache restore",
        defined?(PG) && "sem-service start postgres",
        "sem-version ruby #{RUBY_VERSION}",
        "bundle install",
        "cache store"
      ].select(&:itself)
    }
  },
  "blocks" => [
    {
      "name" => "Test",
      "task" => {
        "jobs" => [
          {
            "name" => "Run tests",
            "commands" => [
              "bundle exec rails db:setup",
              gem_installed?("rspec-rails") && "bundle exec rspec"
            ].select(&:itself)
          }
        ]
      }
    },
    {
      "name" => "Lint",
      "task" => {
        "jobs" => [
          {
            "name" => "Run quality",
            "commands" => [
              gem_installed?("bundler-audit") && "bundle exec bundler-audit --update",
              gem_installed?("brakeman") && "bundle exec brakeman",
              gem_installed?("rubocop") && "bundle exec rubocop --parallel"
            ].select(&:itself)
          }
        ]
      }
    }
  ]
}

linter_commands = semaphore_config["blocks"][1]["task"]["jobs"][0]["commands"]
semaphore_config["blocks"].pop if linter_commands.empty?

file ".semaphore/semaphore.yml", semaphore_config.to_yaml
