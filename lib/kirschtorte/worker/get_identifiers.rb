require 'bundler/setup'
require 'base64'
require 'json'
require 'minty-rb'

module Kirschtorte
  module Worker
    class GetIdentifiers
      @queue = :ingest

      def self.perform payload
        g = Kirschtorte::Worker::Generic.new payload
        identifiers = self.mint_and_bind sip_path: g.package.get(:sip_path),
                                         dark_archive: g.package.get(:dark_archive)

        g.package.set(:aip_identifier, identifiers[:aip_id])
        unless g.package.get(:dark_archive)
          g.package.set(:dip_identifier, identifiers[:dip_id])
        end
        g.package.save

        if g.package.get(:aip_identifier) == identifiers[:aip_id]
          puts "GetIdentifiers: #{identifiers.to_json}"
          g.task.complete!
        else
          puts "GetIdentifiers: FAILED"
          g.task.fail!
        end
      end

      def self.mint_and_bind options
        minter = MintyRb::Minter.new File.join('config', 'minter.yml')
        binder = MintyRb::Binder.new File.join('config', 'binder.yml')

        identifiers = {sip_id: File.basename(options[:sip_path])}
        identifiers[:aip_id] = minter.mint

        unless options[:dark_archive]
          identifiers[:dip_id] = minter.mint

          binder.bind identifiers[:dip_id],
                      identifiers.merge({old_id: identifiers[:aip_id]})
        end

        binder.bind identifiers[:aip_id],
                    identifiers.merge({old_id: identifiers[:sip_id]})

        identifiers
      end
    end
  end
end
