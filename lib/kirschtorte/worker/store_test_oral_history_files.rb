require 'bundler/setup'
require 'pairtree'
require 'rsync'

module Kirschtorte
  module Worker
    class StoreTestOralHistoryFiles
      @queue = :ingest

      def self.perform payload
        g = Kirschtorte::Worker::Generic.new payload
        dip_id = g.package.get(:dip_identifier)

        oral_history = g.package.get(:oral_history)
        dark_archive = g.package.get(:dark_archive)

        if dark_archive
          puts "SKIPPED StoreTestOralHistoryFiles for #{dip_id} (dark archive)"
          g.task.complete!
          return
        end

        unless oral_history
          puts "SKIPPED StoreTestOralHistoryFiles for #{dip_id} (not an oral history)"
          g.task.complete!
          return
        end

        config = YAML.load_file File.join('config', 'abby_normal.yml')
        dip_tree = Pairtree.at(config['local']['dip_dir'], create: true)
        dip_path = dip_tree.get(dip_id).path

        username = config['staging']['username']
        server = config['staging']['oh_host']
        remote_oh_dir = config['staging']['oh_dir']

        Rsync.run("#{dip_path}/data/",
                  "#{username}@#{server}:#{remote_oh_dir}",
                  ["-aPOK"]) do |result|
          if result.success?
            puts "StoreTestOralHistoryFiles: #{dip_path} -> #{server}:#{remote_oh_dir} succeeded"
            g.task.complete!
          else
            puts "StoreTestOralHistoryFiles: #{dip_path} -> #{server}:#{remote_oh_dir} failed"
            g.task.fail!
          end
        end
      end
    end
  end
end
