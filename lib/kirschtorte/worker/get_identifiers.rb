require 'bundler/setup'
require 'minty-rb'

module Kirschtorte
  module Worker
    class GetIdentifiers
      def self.perform payload
        # mint any appropriate identifiers
        # mark task completed or failed
      end
    end
  end
end
