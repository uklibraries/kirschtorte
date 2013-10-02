require 'bundler/setup'
require 'base64'
require 'json'
require 'minty-rb'

module Kirschtorte
  module Worker
    class GetIdentifiers
      @queue = :ingest

      def self.perform payload
        data = JSON.parse Base64.strict_decode64(payload), 
                          symbolize_names: true
        client = Client.new File.join('config', 'abby_normal.yml')
        package = Model::Package.new data: data[:package], client: client
        task = Model::Task.new data: data[:task], client: client

        identifiers = self.mint_and_bind sip_path: package.get(:sip_path),
                                         dark_archive: package.get(:dark_archive)

        package.set(:aip_identifier, identifiers[:aip_id])
        unless package.get(:dark_archive)
          package.set(:dip_identifier, identifiers[:dip_id])
        end
        package.save

        if package.get(:aip_identifier) == identifiers[:aip_id]
          puts "GetIdentifiers: #{identifiers.to_json}"
          task.complete!
        else
          puts "GetIdentifiers: FAILED"
          task.fail!
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
