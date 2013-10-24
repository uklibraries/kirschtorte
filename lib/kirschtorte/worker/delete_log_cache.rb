require 'bundler/setup'

module Kirschtorte
  module Worker
    class DeleteLogCache
      @queue = :ingest

      def self.perform payload
        # TODO
        g = Kirschtorte::Worker::Generic.new payload
        g.task.complete!
      end
    end
  end
end
