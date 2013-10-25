require 'bundler/setup'
require 'net/ssh'
require 'pairtree'
require 'rsync'

module Kirschtorte
  module Worker
    class IndexIntoSolr
      @queue = :ingest

      def self.perform payload
        g = Kirschtorte::Worker::Generic.new payload
        dip_id = g.package.get(:dip_identifier)
        dark_archive = g.package.get(:dark_archive)

        if dark_archive
          puts "SKIPPED IndexIntoSolr for #{dip_id} (dark archive)"
          g.task.complete!
          return
        end

        config = YAML.load_file File.join('config', 'abby_normal.yml')
        username = config['production']['username']
        server = config['production']['solr_host']
        remote_path = File.join config['production']['solr_dir'],
                                "pairtree_root",
                                Pairtree::Path.id_to_path(dip_id)

        remote_dir = config['production']['blacklight_dir']
        commands = [
          "cd #{remote_dir}",
          "rake solr:index:json_dir FILE=#{remote_path}",
        ].join('; ')

        Net::SSH.start(server, username) do |ssh|
          output = ssh.exec!(commands)
          puts "IndexIntoSolr: #{output}"
        end
        if output.lines.last =~ /{"responseHeader"=>{"QTime"=>\d+, "status"=>0}}/
          puts "IndexIntoSolr: #{solr_path} -> #{server}:#{remote_path} succeeded"
          g.task.complete!
        else
          puts "IndexIntoSolr: #{solr_path} -> #{server}:#{remote_path} failed"
          g.task.fail!
        end

        puts "IndexIntoSolr: #{server}:#{remote_path} succeeded"
        g.task.complete!
      end
    end
  end
end
