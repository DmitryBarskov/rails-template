# frozen_string_literal: true

def gem_installed?(gem_name)
  Gem::Specification.find_by_name(gem_name)
rescue Gem::LoadError
  nil
end

file ".semaphore/semaphore.yml", <<~YAML
  version: v1.0
  name: Ruby on Rails CI
  agent:
    machine:
      type: e1-standard-2
      os_image: ubuntu2004
  execution_time_limit:
    minutes: 10
  auto_cancel:
    running:
      when: true
  fail_fast:
    stop:
      when: true

  global_job_config:
    prologue:
      commands:
        - checkout
        - cache restore
        #{'- sem-service start postgres' if defined? PG}
        - sem-version ruby #{RUBY_VERSION}
        - bundle install
        - cache store

  blocks:
    - name: Test
      task:
        jobs:
          - name: Run tests
            commands:
              - bundle exec rails db:setup
              #{'- bundle exec rspec' if gem_installed? 'rspec-rails'}

    - name: Lint
      task:
        jobs:
          - name: Run quality
            commands:
              #{'- bundle exec bundler-audit --update' if gem_installed? 'bundler-audit'}
              #{'- bundle exec brakeman' if gem_installed? 'brakeman'}
              #{'- bundle exec rubocop  --parallel' if gem_installed? 'rubocop'}
YAML
