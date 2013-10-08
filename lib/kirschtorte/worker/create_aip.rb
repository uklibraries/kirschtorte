require 'bundler/setup'
require 'bagit'
require 'kdl/embaggen'
require 'pairtree'

# This class requires Unix-style paths.

module Kirschtorte
  module Worker
    class CreateAip
      @queue = :ingest

      def self.perform payload
        g = Kirschtorte::Worker::Generic.new payload
        config = YAML.load_file File.join('config', 'abby_normal.yml')
        sip_tree = Pairtree.at(config['local']['sip_dir'], create: true)
        aip_tree = Pairtree.at(config['local']['aip_dir'], create: true)

        sip_path = sip_tree.get(g.package.get(:aip_identifier)).path
        aip_path = aip_tree.mk(g.package.get(:aip_identifier)).path

        begin
          aip = KDL::Embaggen.new aip_path
          aip.add_directory sip_path
          aip.manifest!
          puts "CreateAip: #{sip_path} -> #{aip_path} succeeded"
          g.task.complete!
        rescue
          puts "CreateAip: #{sip_path} -> #{aip_path} failed"
          g.task.fail!
        end
      end
    end
  end
end
