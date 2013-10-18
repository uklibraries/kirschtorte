require 'bundler/setup'
require 'net/ssh'
require 'pairtree'

module Kirschtorte
  module Worker
    class StoreTestDip
      @queue = :ingest

      def self.perform payload
        g = Kirschtorte::Worker::Generic.new payload
        dark_archive = g.package.get(:dark_archive)

        unless dark_archive
          config = YAML.load_file File.join('config', 'abby_normal.yml')
          dip_tree = Pairtree.at(config['local']['dip_dir'], create: true)
          dip_id = g.package.get(:dip_identifier)
          dip_path = dip_tree.get(dip_id).path
  
          username = config['staging']['username']
          server = config['staging']['dips_host']
          remote_dips_dir = config['staging']['dip_dir']
          remote_path = File.join remote_dips_dir,
                                  "pairtree_root",
                                  Pairtree::Path.id_to_path(dip_id)
  
          Net::SSH.start(server, username) do |ssh|
            ssh.exec!("/bin/mkdir -p #{remote_path}")
          end
  
          Rsync.run("#{dip_path}/", 
                    "#{username}@#{server}:#{remote_path}",
                    ["-aPOK"]) do |result|
            if result.success?
              puts "StoreTestDip: #{dip_path} -> #{server}:#{remote_path} succeeded"
              g.task.complete!
            else
              puts "StoreTestDip: #{dip_path} -> #{server}:#{remote_path} failed"
              g.task.fail!
            end
          end
        else
          puts "SKIPPED StoreTestDip for #{g.package.get(:dip_identifier)} (dark archive)"
          g.task.complete!
        end
      end
    end
  end
end
