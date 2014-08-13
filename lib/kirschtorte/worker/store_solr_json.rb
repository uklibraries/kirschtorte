require 'bundler/setup'
require 'net/ssh'
require 'pairtree'
require 'rsync'

module Kirschtorte
  module Worker
    class StoreSolrJson
      @queue = :ingest

      def self.perform payload
        g = Kirschtorte::Worker::Generic.new payload
        dip_id = g.package.get(:dip_identifier)
        dark_archive = g.package.get(:dark_archive)

        if dark_archive
          puts "SKIPPED StoreSolrJson for #{dip_id} (dark archive)"
          g.task.complete!
          return
        end

        config = YAML.load_file File.join('config', 'abby_normal.yml')
        solr_tree = Pairtree.at(config['local']['solr_dir'], create: true)
        solr_path = solr_tree.get(dip_id).path

        username = config['production']['username']
        server = config['production']['solr_host']
        remote_path = File.join config['production']['solr_dir'],
                                "pairtree_root",
                                Pairtree::Path.id_to_path(dip_id)

        Net::SSH.start(server, username) do |ssh|
          ssh.exec!("/bin/mkdir -p #{remote_path}")
        end

        Rsync.run("#{solr_path}/",
                  "#{username}@#{server}:#{remote_path}",
                  ["-aPOK"]) do |result|
          if result.success?
            local_checksum = %x[#{File.join('bin', 'solr_checksum')} #{solr_path}]
            remote_checksum = ""
            Net::SSH.start(server, username) do |ssh|
              remote_checksum = ssh.exec!("#{config['production']['solr_checksum']} #{remote_path}")
            end

            if local_checksum == remote_checksum
              puts "StoreSolrJson: #{solr_path} -> #{server}:#{remote_path} succeeded"
              g.task.complete!
            else
              puts "StoreSolrJson: #{solr_path} -> #{server}:#{remote_path} failed (bad checksum)"
              g.task.fail!
            end
          else
            puts "StoreSolrJson: #{solr_path} -> #{server}:#{remote_path} failed"
            g.task.fail!
          end
        end
      end
    end
  end
end
