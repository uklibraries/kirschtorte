require 'bundler/setup'
require 'kdl/access_package'
require 'kdl/solr_maker'
require 'pairtree'

module Kirschtorte
  module Worker
    class CreateSolrJson
      @queue = :ingest

      def self.perform payload
        g = Kirschtorte::Worker::Generic.new payload
        dip_id = g.package.get(:dip_identifier)
        dark_archive = g.package.get(:dark_archive)

        if dark_archive
          puts "SKIPPED CreateSolrJson for #{dip_id} (dark archive)"
          g.task.complete!
          return
        end

        config = YAML.load_file File.join('config', 'abby_normal.yml')
        dip_tree = Pairtree.at(config['local']['dip_dir'], create: true)
        dip_path = dip_tree.get(dip_id).path
        solr_tree = Pairtree.at(config['local']['solr_dir'], create: true)
        solr_path = solr_tree.mk(dip_id).path

        access_package = KDL::AccessPackage.new dip_path
        solr_maker = KDL::SolrMaker.new STDOUT,
                                        access_package,
                                        File.dirname(solr_path)
        solr_maker.build
        puts "CreateSolrJson: #{dip_path} -> #{solr_path} succeeded"
        g.task.complete!
      end
    end
  end
end
