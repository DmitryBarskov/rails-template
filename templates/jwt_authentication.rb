# frozen_string_literal: true

def source_paths
  [__dir__]
end

gem "jwt"

run_bundle

generate(
  :model,
  "refresh_token token::index user:references expires_at:date jti::index"
)
rails_command "db:migrate"

copy_file(
  "files/identification_service.rb",
  "app/services/identification_service.rb"
)

copy_file(
  "files/authentication_service.rb",
  "app/services/authentication_service.rb"
)

if defined?(RSpec)
  copy_file(
    "files/identification_service_spec.rb",
    "spec/services/identification_service_spec.rb"
  )

  copy_file(
    "files/authentication_service_spec.rb",
    "spec/services/authentication_service_spec.rb"
  )
end
