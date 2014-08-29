require 'bundler/setup'
require 'kirschtorte/client'
require 'kirschtorte/model'
require 'json'
require 'trello'

module Kirschtorte
  class NdnpSubmitter
    def initialize
      @client = Client.new File.join('config', 'abby_normal.yml')
      trello = YAML.load(IO.read File.join('config', 'trello.yml'))
      @board = trello["board"]
      Trello.configure do |config|
        config.developer_public_key = trello["developer"]
        config.member_token = trello["member"]
      end
    end

    def plan
      #puts "Reading board..."
      board = Trello::Board.find(@board)

      special = {}
      board.lists.each do |list|
          if list.name =~ /ndnp sip supply/i
              special[:supply] = list
          elsif list.name =~ /ready to ingest/i
              special[:ready] = list
          elsif list.name =~ /in abby normal/i
              special[:abby] = list
          end
      end

      # pick up next card to ingest
      card_to_ingest = nil
      special[:ready].cards.each do |card|
          if card.labels.select {|l| l.name}.count > 0
              card_to_ingest = card
              break
          end
      end

      server_id = ((card_to_ingest.name.gsub(/\D/, '').to_i - 1) % 3) + 1

      data = {
        :name => card_to_ingest.name,
        :discussion_link => card_to_ingest.url,
        :batch_type_id => 4, # hardcoded for NDNP
        :server_id => server_id,
        :oral_history => false,
        :dark_archive => false,
        :reprocessing => false,
      }
      puts data.to_json
      
      @batch = Model::Batch.new data: data, client: @client
    end

    def submit
      plan
      @batch.create
    end
  end
end
