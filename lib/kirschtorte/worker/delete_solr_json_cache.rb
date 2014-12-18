require 'bundler/setup'
require 'pairtree'

module Kirschtorte
  module Worker
    class DeleteSolrJsonCache
      @queue = :ingest

      def self.perform payload
        g = Kirschtorte::Worker::Generic.new payload
        dark_archive = g.package.get(:dark_archive)
        aip_id = g.package.get(:aip_id)

        if dark_archive
          puts "SKIPPED DeleteSolrJsonCache for #{aip_id} (dark archive)"
          g.task.complete!
          return
        end

        config = YAML.load_file File.join('config', 'abby_normal.yml')
        solr_tree = Pairtree.at(config['local']['solr_dir'], create: true)
        dip_id = g.package.get(:dip_identifier)
        solr_path = solr_tree.get(dip_id).path

        username = config['staging']['username']

        # Attempt to unindex from test server.
        #
        # Failing this attempt is not a failing condition
        # for the job, but may require some cleanup later.
        remote_dir = config['staging']['blacklight_dir']
        remote_path = File.join config['staging']['solr_dir'],
                                "pairtree_root",
                                Pairtree::Path.id_to_path(dip_id)
        commands = [
          "cd #{remote_dir}",
          "rake solr:delete_dir DIR=#{remote_path}",
          "/bin/rm -r #{remote_path}",
        ].join('; ')
        server = config['staging']['solr_host']
        Net::SSH.start(server, username) do |ssh|
          output = ssh.exec!(commands)
          puts "DeleteSolrJsonCache: #{output}"
        end

        # Attempt to remove test DIP.
        #
        # Failing this attempt is not a failing condition
        # for the job, but may require some cleanup later.
        test_dip_path = File.join config['staging']['dip_dir'],
                                  "pairtree_root",
                                  Pairtree::Path.id_to_path(dip_id)
        server = config['staging']['dips_host']
        command = "/bin/rm -r #{test_dip_path}"
        Net::SSH.start(server, username) do |ssh|
          output = ssh.exec!(command)
          puts "DeleteSolrJsonCache: #{output}"
        end

        # Attempt to remove Solr cache from processing
        # server.  This MUST succeed or the job has
        # failed.
        FileUtils.rm_rf(solr_path, secure: true)
        unless File.exist?(solr_path)
          puts "DeleteSolrJsonCache: #{solr_path} succeeded"
          g.task.complete!
        else
          puts "DeleteSolrJsonCache: #{solr_path} failed"
          g.task.fail!
        end
      end
    end
  end
end
