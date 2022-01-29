# frozen_string_literal: true

require_relative "../lib/enable_extension"

gem "bcrypt"
run_bundle

rails_command "db:setup"

if defined? PG
  enable_extension "citext"
  rails_command "db:migrate"
  enable_extension "pgcrypto"
  rails_command "db:migrate"
end

args = %w[user first_name last_name password_digest]
args << if defined? PG
          "email:citext:uniq"
        else
          "email:string:uniq"
        end
args << "--primary-key-type=uuid" if defined? PG

generate :model, args.join(" ")

rails_command "db:migrate"
