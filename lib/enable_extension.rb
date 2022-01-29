# frozen_string_literal: true

def enable_extension(
  extension_name,
  migration_name: "Enable#{extension_name.camelize}",
  current_time: Time.zone.now.strftime("%Y%m%d%H%M%S")
)
  file(
    "db/migrate/#{current_time}_#{migration_name.underscore}.rb",
    <<-RUBY.strip_heredoc
      # #{migration_name.titleize} extension
      class #{migration_name} < ActiveRecord::Migration[7.0]
        def change
          enable_extension '#{extension_name}'
        end
      end
    RUBY
  )
end
