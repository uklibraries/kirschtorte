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
      @board_id = trello["board"]
      Trello.configure do |config|
        config.developer_public_key = trello["developer"]
        config.member_token = trello["member"]
      end
    end

    def plan
      @board = Trello::Board.find(@board_id)

      @special = {}
      @board.lists.each do |list|
          if list.name =~ /ndnp sip supply/i
              @special[:supply] = list
          elsif list.name =~ /ready to ingest/i
              @special[:ready] = list
          elsif list.name =~ /in abby normal/i
              @special[:abby] = list
          end
      end
    end

    def ingest_next_card
      card_to_ingest = nil
      @special[:ready].cards.each do |card|
          if card.labels.select {|l| l.name =~ /ndnp/i}.count > 0
              card_to_ingest = card
              break
          end
      end

      return false unless card_to_ingest

      server_id = ((card_to_ingest.name.gsub(/\D/, '').to_i - 1) % 3) + 1

      data = {
        :name => card_to_ingest.name,
        :discussion_link => card_to_ingest.url,
        :batch_type_id => 4, # hardcoded for NDNP
        :server_id => server_id,
        :oral_history => false,
        :dark_archive => true,
        :generate_dip_identifiers => true,
        :reprocessing => false,
      }
      puts "Submitting #{card_to_ingest.name} to Abby Normal"
      @batch = Model::Batch.new data: data, client: @client
      @batch.create
      puts "Moving to #{@special[:abby].name}"
      card_to_ingest.move_to_list(@special[:abby])
      true
    end

    def pull_from_supply
      return unless @special[:supply].cards.count > 0
      card = @special[:supply].cards.first

      # Add the NDNP label to the card.
      # The API requires us to specify the label by color.
      # We're hardcoding the color for now, but should
      # actually fetch it by name.
      card.add_label("blue")
      card.add_member(Trello::Member.find("me"))
      puts "Adding #{card.name} to #{@special[:ready].name}"
      card.move_to_list(@special[:ready])
    end

    def submit
      plan
      return unless ingest_next_card
      pull_from_supply
    end
  end
end
