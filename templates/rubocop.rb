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

  I18n/GetText/DecorateString:
    Exclude:
      - spec/**/*.rb

  I18n/RailsI18n/DecorateString:
    Exclude:
      - spec/**/*.rb

  Style/Documentation:
    Enabled: false

  Style/StringLiterals:
    EnforcedStyle: double_quotes
YAML

append_to_file ".gitattributes" do
  "\nbin/rubocop linguist-generated\n"
end

run "bundle binstubs rubocop"

files_count = Dir["app/**/*", "lib/**/*", "spec/**/*", "test/**/*", "config/**/*"].length
run "bin/rubocop --auto-gen-config --auto-gen-only-exclude --exclude-limit #{files_count}"
