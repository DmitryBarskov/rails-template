# frozen_string_literal: true

question = "Would you like to Slim generators for Rails 3+ too (a.k.a. slim-rails)?"
slim_gem = yes?(question) ? "slim-rails" : "slim"

gem slim_gem
run_bundle
