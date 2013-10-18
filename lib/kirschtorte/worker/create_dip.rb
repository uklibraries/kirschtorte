require 'bundler/setup'
require 'kdl/dip_maker'
require 'pairtree'

module Kirschtorte
  module Worker
    class CreateDip
      @queue = :ingest

      def self.perform payload
        g = Kirschtorte::Worker::Generic.new payload
        dip_id = g.package.get(:dip_identifier)
        dark_archive = g.package.get(:dark_archive)

        if dark_archive
          puts "SKIPPED CreateDip for #{dip_id} (dark archive)"
          g.task.complete!
          return
        end

        config = YAML.load_file File.join('config', 'abby_normal.yml')
        aip_tree = Pairtree.at(config['local']['aip_dir'], create: true)
        dip_tree = Pairtree.at(config['local']['dip_dir'], create: true)

        aip_path = aip_tree.get(g.package.get(:aip_identifier)).path
        dip_path = dip_tree.mk(dip_id).path

        dipmaker = KDL::DipMaker.new STDOUT,
                   aip_path,
                   File.dirname(dip_path),
                   :dip_directory => dip_id
        dipmaker.build
        g.task.complete!
      end
    end
  end
end
