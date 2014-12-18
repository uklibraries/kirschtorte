require 'bundler/setup'
require 'pairtree'

module Kirschtorte
  module Worker
    class DeleteAipCache
      @queue = :ingest

      def self.perform payload
        g = Kirschtorte::Worker::Generic.new payload
        config = YAML.load_file File.join('config', 'abby_normal.yml')
        aip_tree = Pairtree.at(config['local']['aip_dir'], create: true)
        aip_id = g.package.get(:aip_identifier)
        aip_path = aip_tree.get(aip_id).path

        FileUtils.rm_rf(aip_path, secure: true)
        unless File.exist?(aip_path)
          puts "DeleteAipCache: #{aip_path} succeeded"
          g.task.complete!
        else
          puts "DeleteAipCache: #{aip_path} failed"
          g.task.fail!
        end
      end
    end
  end
end
