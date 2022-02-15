# frozen_string_literal: true

require "net/http"

BASE_URL = "https://raw.githubusercontent.com/DmitryBarskov/rails-template/main"

# downloads the content of a file from the github repository
def get_gh_file_content(filename)
  uri = "#{BASE_URL}/#{filename}"
  Net::HTTP.get(URI(uri))
end
