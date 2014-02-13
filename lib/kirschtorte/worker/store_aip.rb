require 'bundler/setup'
require 'net/ssh'
require 'pairtree'
require 'rsync'

module Kirschtorte
  module Worker
    class StoreAip
      @queue = :ingest

      def self.perform payload
        g = Kirschtorte::Worker::Generic.new payload
        dark_archive = g.package.get(:dark_archive)

        config = YAML.load_file File.join('config', 'abby_normal.yml')
        aip_tree = Pairtree.at(config['local']['aip_dir'], create: true)
        aip_id = g.package.get(:aip_identifier)
        aip_path = aip_tree.get(aip_id).path

        remote_aips_dir = config['production']['aip_dir']
        remote_path = File.join remote_aips_dir,
                                "pairtree_root",
                                Pairtree::Path.id_to_path(aip_id)

        system("/bin/mkdir -p #{remote_path}")

        Rsync.run("#{aip_path}/",
                  "#{remote_path}",
                  ["-aPOK"]) do |result|
          if result.success?
            bag = BagIt::Bag.new remote_path

            if bag.valid?
              g.package.set(:remote_aip_fixed, true)
              g.package.save
              puts "StoreAip: #{aip_path} -> #{remote_path} succeeded"
              g.task.complete!
            else
              g.package.set(:remote_aip_fixed, false)
              g.package.save
              puts "StoreAip: #{aip_path} -> #{remote_path} failed (invalid bag)"
              g.task.fail!
            end
          else
            g.package.set(:remote_aip_fixed, false)
            g.package.save
            puts "StoreAip: #{aip_path} -> #{remote_path} failed (rsync returned false)"
            g.task.fail!
          end
        end
      end
    end
  end
end
