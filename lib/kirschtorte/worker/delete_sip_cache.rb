require 'bundler/setup'
require 'pairtree'

module Kirschtorte
  module Worker
    class DeleteSipCache
      @queue = :ingest

      def self.perform payload
        g = Kirschtorte::Worker::Generic.new payload
        config = YAML.load_file File.join('config', 'abby_normal.yml')
        sip_tree = Pairtree.at(config['local']['sip_dir'], create: true)
        sip_id = g.package.get(:aip_identifier)
        sip_path = sip_tree.get(sip_id).path

        FileUtils.rm_rf(sip_path, secure: true)
        unless File.exist?(sip_path)
          puts "DeleteSipCache: #{sip_path} succeeded"
          g.task.complete!
        else
          puts "DeleteSipCache: #{sip_path} failed"
          g.task.fail!
        end
      end
    end
  end
end
