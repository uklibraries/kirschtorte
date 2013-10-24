require 'bundler/setup'

module Kirschtorte
  module Worker
    class StoreLogs
      @queue = :ingest

      def self.perform payload
        # TODO
        g.task.complete!
      end
    end
  end
end
