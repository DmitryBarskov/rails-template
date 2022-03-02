# frozen_string_literal: true

def source_paths
  [__dir__]
end

gem_group :development, :test do
  gem "rspec-rails"
end

run_bundle
generate "rspec:install"
run "bundle binstubs rspec-core"

copy_file("files/spec/spec_helper.rb", "spec/spec_helper.rb")
copy_file("files/spec/rails_helper.rb", "spec/rails_helper.rb")

append_to_file ".gitignore" do
  "\nspec/examples.txt\n"
end
