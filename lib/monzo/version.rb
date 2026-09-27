# frozen_string_literal: true

module Monzo
  VERSION = '0.1.0'

  # The document this gem exists to ship. Everything else here reads it at
  # runtime rather than restating it.
  SCHEMA = File.expand_path('../../monzo_api.yaml', __dir__)
end
