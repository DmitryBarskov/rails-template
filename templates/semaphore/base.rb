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
        "sem-version ruby #{RUBY_VERSION}",
        "bundle install",
        "cache store"
      ]
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
              "bundle exec rails db:setup"
            ]
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
            "commands" => []
          }
        ]
      }
    }
  ]
}

if defined? PG
  semaphore_config["global_job_config"]["prologue"]["commands"].insert(2, "sem-service start postgres")
end

if gem_installed? "rspec-rails"
  semaphore_config["blocks"][0]["task"]["jobs"][0]["commands"] << "bundle exec rspec"
else
  semaphore_config["blocks"].shift
end

quality_gems = {
  "bundler-audit" => "bundle exec bundler-audit --update",
  "brakeman" => "bundle exec brakeman",
  "rubocop" => "bundle exec rubocop  --parallel"
}

quality_gems.each_pair do |gem, command|
  if gem_installed? gem
    semaphore_config["blocks"][-1]["task"]["jobs"][0]["commands"] << command
  end
end

if semaphore_config["blocks"][-1]["task"]["jobs"][0]["commands"].empty?
  semaphore_config["blocks"].pop
end

if semaphore_config["blocks"].empty?
  raise ScriptError, "
    You don't have any of required gems.
    Install one or feel free to open issue: https://github.com/DmitryBarskov/rails-template/issues/new/choose
  "
end

file ".semaphore/semaphore.yml", semaphore_config.to_yaml[4..]
