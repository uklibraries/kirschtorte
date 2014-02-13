require 'bundler/setup'
require 'net/ssh'
require 'pairtree'
require 'rsync'

module Kirschtorte
  module Worker
    class StoreTestDip
      @queue = :ingest

      def self.perform payload
        g = Kirschtorte::Worker::Generic.new payload
        dark_archive = g.package.get(:dark_archive)

        unless dark_archive
          config = YAML.load_file File.join('config', 'abby_normal.yml')
          dip_tree = Pairtree.at(config['local']['dip_dir'], create: true)
          dip_id = g.package.get(:dip_identifier)
          dip_path = dip_tree.get(dip_id).path

          remote_dips_dir = config['staging']['dip_dir']
          remote_path = File.join remote_dips_dir,
                                  "pairtree_root",
                                  Pairtree::Path.id_to_path(dip_id)

          system("/bin/mkdir -p #{remote_path}")

          Rsync.run("#{dip_path}/",
                    "#{remote_path}",
                    ["-aPOK"]) do |result|
            if result.success?
              bag = BagIt::Bag.new remote_path

              if bag.valid?
                g.package.set(:remote_test_dip_fixed, true)
                g.package.save
                puts "StoreTestDip: #{dip_path} -> #{remote_path} succeeded"
                g.task.complete!
              else
                g.package.set(:remote_test_dip_fixed, false)
                g.package.save
                puts "StoreTestDip: #{dip_path} -> #{remote_path} failed (invalid bag)"
                g.task.fail!
              end
            else
              g.package.set(:remote_test_dip_fixed, false)
              g.package.save
              puts "StoreTestDip: #{dip_path} -> #{remote_path} failed (rsync returned false)"
              g.task.fail!
            end
          end
        else
          puts "SKIPPED StoreTestDip for #{g.package.get(:dip_identifier)} (dark archive)"
          g.task.complete!
        end
      end
    end
  end
end
