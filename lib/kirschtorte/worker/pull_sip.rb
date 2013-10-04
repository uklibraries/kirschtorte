require 'bundler/setup'
require 'pairtree'
require 'rsync'

# This class requires Unix-style paths.

module Kirschtorte
  module Worker
    class PullSip
      @queue = :ingest

      def self.perform payload
        g = Kirschtorte::Worker::Generic.new payload
        config = YAML.load_file File.join('config', 'abby_normal.yml')
        pairtree = Pairtree.at(config['local']['sip_dir'], create: true)

        source = [
          config['source']['username'],
          '@',
          config['source']['host'] ,
          ':',
          g.package.get(:sip_path),
          '/',
        ].join('')

        target = pairtree.mk(g.package.get(:aip_identifier)).path

        Rsync.run(source, target, ["-aPOK"]) do |result|
          if result.success?
            puts "PullSip: #{source} -> #{target} succeeded"
            g.task.complete!
          else
            puts "PullSip: #{source} -> #{target} failed"
            g.task.fail!
          end
        end
      end
    end
  end
end
