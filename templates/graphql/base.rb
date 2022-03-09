# frozen_string_literal: true

def source_paths
  [__dir__]
end

unless defined? GraphQL
  gem "graphql"
  run_bundle
end

unless defined? ApplicationSchema
  rails_command "generate graphql:install --schema=ApplicationSchema"
  run_bundle

  copy_file(
    "files/graphql_controller.rb",
    "app/controllers/graphql_controller.rb"
  )
end
