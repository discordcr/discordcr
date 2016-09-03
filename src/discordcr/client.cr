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

    OP_DISPATCH = 0
    OP_HELLO = 10

    private def on_message(message : String)
      packet = GatewayPacket.from_json(message)

      case packet.op
      when OP_HELLO
        handle_hello(packet.d["heartbeat_interval"])
      when OP_DISPATCH
        handle_dispatch(packet.t, packet.d)
      else
        puts "Unsupported message: #{message}"
      end

      nil
    end

    private def handle_hello(heartbeat_interval)
      setup_heartbeats
      identify
    end

    private def setup_heartbeats(heartbeat_interval)
      spawn do
        loop do
          puts "Sending heartbeat"
          @websocket.not_nil!.send({op: 1, d: 0}.to_json)
          sleep heartbeat_interval.as_i.milliseconds
        end
      end
    end

    private def identify
      spawn do
        packet = {
          op: 2,
          d: {
            token: @token,
            properties: {
              :"$os" => "Crystal",
              :"$browser" => "discordcr",
              :"$device" => "discordcr",
              :"$referrer" => "",
              :"$referring_domain" => ""
            },
            compress: false,
            large_threshold: 100
          }
        }.to_json
        @websocket.not_nil!.send(packet)
      end
    end

    private def handle_dispatch(type, data)
      case type
      when "READY"
        puts "Received READY, v: #{data["v"]}"
      when "MESSAGE_CREATE"
        puts "Received message with content #{data["content"]}"
        @on_message.try &.call(data["content"].to_s)
      else
        puts "Unsupported dispatch: #{type} #{data}"
      end
    end

    def on_message(&@on_message : String ->)
    end
  end
end
