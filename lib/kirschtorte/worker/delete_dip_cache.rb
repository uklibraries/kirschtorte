require 'bundler/setup'
require 'pairtree'

module Kirschtorte
  module Worker
    class DeleteDipCache
      @queue = :ingest

      def self.perform payload
        g = Kirschtorte::Worker::Generic.new payload
        dark_archive = g.package.get(:dark_archive)
        aip_id = g.package.get(:aip_id)

        if dark_archive
          puts "SKIPPED DeleteDipCache for #{aip_id} (dark archive)"
          g.task.complete!
          return
        end

        config = YAML.load_file File.join('config', 'abby_normal.yml')
        dip_tree = Pairtree.at(config['local']['dip_dir'], create: true)
        dip_id = g.package.get(:dip_identifier)
        dip_path = dip_tree.get(dip_id).path

        FileUtils.rm_rf(dip_path, secure: true)
        unless File.exist?(dip_path)
          puts "DeleteDipCache: #{dip_path} succeeded"
          g.task.complete!
        else
          puts "DeleteDipCache: #{dip_path} failed"
          g.task.fail!
        end
      end
    end
  end
end
