require 'bundler/setup'
require 'bagit'
require 'pairtree'

module Kirschtorte
  module Worker
    class CheckLocalDipFixity
      @queue = :fixity

      def self.perform payload
        g = Kirschtorte::Worker::Generic.new payload
        config = YAML.load_file File.join('config', 'abby_normal.yml')
        dip_tree = Pairtree.at(config['local']['dip_dir'], create: true)
        dip_path = dip_tree.get(g.package.get(:dip_identifier)).path

        bag = BagIt::Bag.new dip_path
        g.package.set(:local_dip_fixed, bag.valid?)
      end
    end
  end
end
