require "http/web_socket"

require "./rest"

module Discordcr
  class Client
    include REST

    def initialize(@token : String, @client_id : UInt64)
    end

    def run
      url = gateway.url
      url += "?v=6&encoding=json"
      @websocket = HTTP::WebSocket.new(URI.parse(url))
    end

    private def on_message(message : String)
    end
  end
end
