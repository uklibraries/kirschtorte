require 'bundler/setup'
require 'json'
require 'trello'

module Kirschtorte
  class NdnpSupplier
    def initialize options
      @stem = options[:stem]
      @count = options[:count].to_i
      trello = YAML.load(IO.read File.join('config', 'trello.yml'))
      @board_id = trello["board"]
      Trello.configure do |config|
        config.developer_public_key = trello["developer"]
        config.member_token = trello["member"]
      end
    end

    def supply
      @board = Trello::Board.find(@board_id)

      @special = {}
      @board.lists.each do |list|
          if list.name =~ /ndnp sip supply/i
              @special[:supply] = list
          end
      end

      return unless @special[:supply]
      idList = @special[:supply].id
      width = 1 + Math.log10(@count).floor
      format = "%0#{width}d"

      (1..@count).each do |n|
        batch_name = [@stem, sprintf(format, n)].join('_')
        puts "Queueing #{batch_name}"
        Trello::Card.create(
          name: batch_name,
          list_id: @special[:supply].id,
        )
      end
    end
  end
end
