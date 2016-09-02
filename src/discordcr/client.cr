require "http/websocket"

require "./rest"

module Discordcr
  class Client
    include REST

    def initialize(@token : String, @client_id : UInt64)
    end

    def run
      url = gateway.url
      @websocket = HTTP::WebSocket.new(URI.parse(url))
    end

    private def on_message(String)
    end
  end
end
