# frozen_string_literal: true

gem_group :development, :test do
  gem "factory_bot_rails"
end

run_bundle

if defined? RSpec
  file "spec/support/factory_bot.rb", <<-RUBY
    RSpec.configure do |config|
      config.include FactoryBot::Syntax::Methods
    end
  RUBY
else
  file "test/support/factory_bot.rb", <<-RUBY
    class ActiveSupport::TestCase
      include FactoryBot::Syntax::Methods
    end
  RUBY
end

Dir[Rails.root.join("app/models/**/*.rb")].each { |f| require f }
models = ApplicationRecord.send(:subclasses).map(&:name)
models.each do |model|
  columns = model.constantize.columns
  columns_with_types = columns.map { |column| "#{column.name}:#{column.type}" }
  generate "factory_bot:model", "#{model} #{columns_with_types.join(' ')}"
end
