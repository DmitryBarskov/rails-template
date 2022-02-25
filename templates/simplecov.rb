# frozen_string_literal: true

gem_group :test do
  gem "simplecov", require: false
end
run_bundle

append_to_file ".gitignore" do
  "\n/coverage\n"
end

%w[spec test].each do |directory|
  next unless Dir.exist?(directory)

  file "#{directory}/support/simplecov.rb", <<-RUBY.strip_heredoc
    require "simplecov"

    SimpleCov.start :rails do
      enable_coverage :branch
      primary_coverage :branch
    end
  RUBY
end

if File.exist?("spec/rails_helper.rb")
  insert_into_file "spec/rails_helper.rb", before: 'require "rspec/rails"' do
    "require \"support/simplecov.rb\"\n"
  end
end

if File.exist?("test/test_helper.rb")
  insert_into_file "test/test_helper.rb", before: 'require "rails/test_help"' do
    "require \"test/support/simplecov.rb\"\n"
  end
end
