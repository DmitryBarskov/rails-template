# frozen_string_literal: true

gem_group :development, :test do
  gem "brakeman", require: false
  gem "bundle-audit", require: false
end

run_bundle

run "bundle binstubs brakeman bundle-audit"
run "bin/bundle-audit"
run "bin/brakeman"
