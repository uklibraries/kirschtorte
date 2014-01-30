require 'bundler/setup'
require 'bagit'
require 'pairtree'

module Kirschtorte
  module Worker
    class CheckLocalAipFixity
      @queue = :fixity

      def self.perform payload
        g = Kirschtorte::Worker::Generic.new payload
        config = YAML.load_file File.join('config', 'abby_normal.yml')
        aip_tree = Pairtree.at(config['local']['aip_dir'], create: true)
        aip_path = aip_tree.get(g.package.get(:aip_identifier)).path

        bag = BagIt::Bag.new aip_path
        g.package.set(:local_aip_fixed, bag.valid?)
      end
    end
  end
end
