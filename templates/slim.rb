# frozen_string_literal: true

views_path = "app/views/"
question = "Do you want to start auto-conversion of current templates to slim? IT IS UNSAFE!"

gem "slim-rails"
run_bundle

if yes?(question)
  gem 'html2slim'
  run_bundle
  run "erb2slim -d #{views_path}"
  run 'bundle remove html2slim'
  run_bundle
end
