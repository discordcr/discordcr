require "http/web_socket"
require "json"

require "./rest"

module Discordcr
  class Client
    include REST

    def initialize(@token : String, @client_id : UInt64)
    end

    def run
      url = URI.parse(gateway.url)
      @websocket = websocket = HTTP::WebSocket.new(
        host: url.host.not_nil!,
        path: "#{url.path}/?encoding=json&v=6",
        port: 443,
        tls: true
      )

      websocket.on_message(&->on_message(String))
      websocket.on_close(&->on_close(String))
      websocket.run
    end

    private def on_close(message : String)
      # TODO: make more sophisticated
      puts "Closed with: " + message
    end

    OP_HELLO = 10

    private def on_message(message : String)
      json = JSON.parse(message)

      case json["op"]
      when OP_HELLO
        puts "Hello received"
      else
        puts "Unsupported message: #{message}"
      end
    end
  end
end
