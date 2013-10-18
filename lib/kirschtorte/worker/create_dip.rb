require 'bundler/setup'
require 'kdl/dip_maker'
require 'pairtree'

module Kirschtorte
  module Worker
    class CreateDip
      @queue = :ingest

      def self.perform payload
        g = Kirschtorte::Worker::Generic.new payload
        config = YAML.load_file File.join('config', 'abby_normal.yml')
        aip_tree = Pairtree.at(config['local']['aip_dir'], create: true)
        dip_tree = Pairtree.at(config['local']['dip_dir'], create: true)

        aip_path = aip_tree.get(g.package.get(:aip_identifier)).path
        dip_path = dip_tree.mk(g.package.get(:dip_identifier)).path

        dipmaker = KDL::DipMaker.new STDOUT,
                   aip_path,
                   File.dirname(dip_path),
                   :dip_directory => g.package.get(:dip_identifier)
        dipmaker.build
        g.task.complete!
      end
    end
  end
end
