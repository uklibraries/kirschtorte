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

        FileUtils.rm_r(solr_path, secure: true)
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
