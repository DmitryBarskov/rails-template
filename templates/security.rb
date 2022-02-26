# frozen_string_literal: true

gem_group :development, :test do
  gem "brakeman", require: false
  gem "bundler-audit", require: false
end

run_bundle

run "bundle binstubs brakeman bundler-audit"
run "bin/bundler-audit --update"
run "bin/brakeman"
