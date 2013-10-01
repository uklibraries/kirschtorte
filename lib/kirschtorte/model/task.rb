module Kirschtorte
  module Model
    class Task
      attr_reader :data
  
      def initialize options
        @client = options[:client]
        @data = options[:data]
        @resource = "/tasks/#{@data[:id]}"
      end
  
      def complete!
        @client.submit_request :resource => @resource, 
                               :method => :put,
                               :body => {:name => 'completed'}
      end
  
      def fail!
        @client.submit_request :resource => @resource, 
                               :method => :put,
                               :body => {:name => 'failed'}
      end
    end
  end
end
