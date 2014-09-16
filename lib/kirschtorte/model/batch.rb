module Kirschtorte
  module Model
    class Batch
      attr_reader :data

      def initialize options
        @client = options[:client]
        @data = options[:data]
        if @data.keys.include? :id
          @resource = "/batches/#{@data[:id]}"
        else
          @resource = "/batches/"
        end
        @changed = false
      end

      def set(field, value)
        if @data.keys.include? field and @data[field] != value
          @data[field] = value
          @changed = true
        end
      end
  
      def get(field)
        if @data.keys.include? field
          @data[field]
        end
      end
  
      def create
        @client.submit_request :resource => @resource,
                               :body => {:batch => @data.to_json}
      end
  
      def save
        if @changed
          @client.submit_request :resource => @resource,
                                 :method => :put,
                                 :body => {:id => @data[:id],
                                           :batch => @data.to_json}
          @data = @client.submit_request :resource => @resource,
                                         :method => :get
        end
        @data
      end
    end
  end
end
