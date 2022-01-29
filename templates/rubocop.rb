# frozen_string_literal: true

rubocop_extensions = %w[
  rubocop-rails
  rubocop-i18n
  rubocop-performance
  rubocop-rake
  rubocop-thread_safety
]
rubocop_extensions << "rubocop-graphql" if defined? GraphQL
rubocop_extensions << "rubocop-minitest" if defined? Minitest
rubocop_extensions << "rubocop-rspec" if defined? RSpec

gem_group :development, :test do
  gem "rubocop", require: false

  rubocop_extensions.each do |extension|
    gem extension, require: false
  end
end

run_bundle

file ".rubocop.yml", <<~YAML.strip_heredoc
  require:
    - #{rubocop_extensions.join("\n  - ")}

  AllCops:
    NewCops: enable

  Style/Documentation:
    Enabled: false

  Style/StringLiterals:
    EnforcedStyle: double_quotes
YAML

run "bundle binstubs rubocop"
run "bin/rubocop -A"
