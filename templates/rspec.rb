# frozen_string_literal: true

gem_group :development, :test do
  gem "rspec-rails"
end

run_bundle
generate "rspec:install"
run "bundle binstubs rspec-core"

run "rm spec/spec_helper.rb"
file "spec/spec_helper.rb", <<-RUBY.strip_heredoc
  RSpec.configure do |config|
    config.expect_with :rspec do |expectations|
      expectations.include_chain_clauses_in_custom_matcher_descriptions = true
    end

    config.mock_with :rspec do |mocks|
      mocks.verify_partial_doubles = true
    end
    config.shared_context_metadata_behavior = :apply_to_host_groups
    config.filter_run_when_matching :focus
    config.example_status_persistence_file_path = 'spec/examples.txt'
    config.disable_monkey_patching!
    config.default_formatter = 'doc' if config.files_to_run.one?
    config.profile_examples = 10
    config.order = :random
    Kernel.srand config.seed
  end
RUBY

run "rm spec/rails_helper.rb"
file "spec/rails_helper.rb", <<~RUBY.strip_heredoc
  # frozen_string_literal: true

  require "spec_helper"

  ENV["RAILS_ENV"] ||= "test"
  require_relative "../config/environment"
  abort("The Rails environment is running in production mode!") if Rails.env.production?

  require "rspec/rails"

  Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

  begin
    ActiveRecord::Migration.maintain_test_schema!
  rescue ActiveRecord::PendingMigrationError => e
    puts e.to_s.strip
    exit 1
  end
  RSpec.configure do |config|
    config.fixture_path = "#{::Rails.root}/spec/fixtures"
    config.use_transactional_fixtures = true
    config.infer_spec_type_from_file_location!
    config.filter_rails_from_backtrace!
  end
RUBY
