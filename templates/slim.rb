# frozen_string_literal: true

gem "slim-rails"
run_bundle

if yes?("Do you want to start auto-conversion of current templates to slim? IT IS UNSAFE!")
  gem "html2slim"
  run_bundle
  run "erb2slim -d app/views/"
  run "bundle remove html2slim"
  run_bundle
end
