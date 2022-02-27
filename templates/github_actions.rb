# frozen_string_literal: true

def source_paths
  [__dir__]
end

copy_file(
  "files/.github/workflows/ruby-on-rails.yml",
  ".github/workflows/ruby-on-rails.yml"
)
