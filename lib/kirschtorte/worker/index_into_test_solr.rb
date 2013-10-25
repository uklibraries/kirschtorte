require 'bundler/setup'
require 'net/ssh'
require 'pairtree'
require 'rsync'

module Kirschtorte
  module Worker
    class IndexIntoTestSolr
      @queue = :ingest

      def self.perform payload
        g = Kirschtorte::Worker::Generic.new payload
        dip_id = g.package.get(:dip_identifier)
        dark_archive = g.package.get(:dark_archive)

        if dark_archive
          puts "SKIPPED IndexIntoTestSolr for #{dip_id} (dark archive)"
          g.task.complete!
          return
        end

        config = YAML.load_file File.join('config', 'abby_normal.yml')
        solr_tree = Pairtree.at(config['local']['solr_dir'], create: true)
        solr_path = solr_tree.get(dip_id).path

        username = config['staging']['username']
        server = config['staging']['solr_host']
        remote_path = File.join config['staging']['solr_dir'],
                                "pairtree_root",
                                Pairtree::Path.id_to_path(dip_id)

        Net::SSH.start(server, username) do |ssh|
          ssh.exec!("/bin/mkdir -p #{remote_path}")
        end

        Rsync.run("#{solr_path}/",
                  "#{username}@#{server}:#{remote_path}",
                  ["-aPOK"]) do |result|
          if result.success?
            remote_dir = config['staging']['blacklight_dir']
            commands = [
              "cd #{remote_dir}",
              "rake solr:index:json_dir FILE=#{remote_path}",
            ].join('; ')
            Net::SSH.start(server, username) do |ssh|
              output = ssh.exec!(commands)
              puts "IndexIntoTestSolr: #{output}"
              if output.lines.last =~ /{"responseHeader"=>{"QTime"=>\d+, "status"=>0}}/
                puts "IndexIntoTestSolr: #{solr_path} -> #{server}:#{remote_path} succeeded"
                g.task.complete!
              else
                puts "IndexIntoTestSolr: #{solr_path} -> #{server}:#{remote_path} failed"
                g.task.fail!
              end
            end
          else
            puts "IndexIntoTestSolr: #{solr_path} -> #{server}:#{remote_path} failed"
            g.task.fail!
          end
        end
      end
    end
  end
end
