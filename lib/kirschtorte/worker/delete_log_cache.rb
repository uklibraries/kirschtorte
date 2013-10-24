require 'bundler/setup'

module Kirschtorte
  module Worker
    class DeleteLogCache
      @queue = :ingest

      def self.perform payload
        # TODO
        g.task.complete!
      end
    end
  end
end
