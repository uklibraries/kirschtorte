require 'bundler/setup'
require 'base64'
require 'json'

module Kirschtorte
  module Worker
    class Generic
      attr_accessor :client, :package, :task

      def initialize payload 
        data = JSON.parse Base64.strict_decode64(payload), 
                          symbolize_names: true
        @client = Client.new File.join('config', 'abby_normal.yml')
        @package = Model::Package.new data: data[:package], client: @client
        @task = Model::Task.new data: data[:task], client: @client
      end
    end
  end
end
