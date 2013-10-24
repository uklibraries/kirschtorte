require 'bundler/setup'
require 'net/ssh'
require 'pairtree'
require 'rsync'

module Kirschtorte
  module Worker
    class StoreAip
      @queue = :ingest

      def self.perform payload
        g = Kirschtorte::Worker::Generic.new payload
        dark_archive = g.package.get(:dark_archive)

        config = YAML.load_file File.join('config', 'abby_normal.yml')
        aip_tree = Pairtree.at(config['local']['aip_dir'], create: true)
        aip_id = g.package.get(:aip_identifier)
        aip_path = aip_tree.get(aip_id).path

        username = config['production']['username']
        server = config['production']['aips_host']
        remote_aips_dir = config['production']['aip_dir']
        remote_path = File.join remote_aips_dir,
                                "pairtree_root",
                                Pairtree::Path.id_to_path(aip_id)

        Net::SSH.start(server, username) do |ssh|
          ssh.exec!("/bin/mkdir -p #{remote_path}")
        end

        Rsync.run("#{aip_path}/",
                  "#{username}@#{server}:#{remote_path}",
                  ["-aPOK"]) do |result|
          if result.success?
            puts "StoreAip: #{aip_path} -> #{server}:#{remote_path} succeeded"
            g.task.complete!
          else
            puts "StoreAip: #{aip_path} -> #{server}:#{remote_path} failed"
            g.task.fail!
          end
        end
      end
    end
  end
end
