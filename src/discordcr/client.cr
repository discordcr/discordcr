require "http/web_socket"
require "json"

require "./rest"

module Discord
  class Client
    include REST

    def initialize(@token : String, @client_id : UInt64)
      url = URI.parse(get_gateway.url)
      @websocket = HTTP::WebSocket.new(
        host: url.host.not_nil!,
        path: "#{url.path}/?encoding=json&v=6",
        port: 443,
        tls: true
      )

      @websocket.on_message(&->on_message(String))
      @websocket.on_close(&->on_close(String))
    end

    def run
      @websocket.run
    end

    private def on_close(message : String)
      # TODO: make more sophisticated
      puts "Closed with: " + message
    end

    OP_DISPATCH =  0
    OP_HELLO    = 10

    private def on_message(message : String)
      spawn do
        packet = parse_message(message)

        case packet.opcode
        when OP_HELLO
          payload = Gateway::HelloPayload.from_json(packet.data)
          handle_hello(payload.heartbeat_interval)
        when OP_DISPATCH
          handle_dispatch(packet.event_type, packet.data)
        else
          puts "Unsupported message: #{message}"
        end
      end

      nil
    end

    private def parse_message(message : String)
      parser = JSON::PullParser.new(message)

      opcode = nil
      sequence = nil
      event_type = nil
      data = MemoryIO.new

      parser.read_object do |key|
        case key
        when "op"
          opcode = parser.read_int
        when "d"
          # Read the raw JSON into memory
          parser.read_raw(data)
        when "s"
          sequence = parser.read_int_or_null
        when "t"
          event_type = parser.read_string_or_null
        else
          # Unknown field
          parser.skip
        end
      end

      # Rewind to beginning of JSON
      data.rewind

      GatewayPacket.new(opcode, sequence, data, event_type)
    end

    private def handle_hello(heartbeat_interval)
      setup_heartbeats(heartbeat_interval)
      identify
    end

    private def setup_heartbeats(heartbeat_interval)
      spawn do
        loop do
          puts "Sending heartbeat"
          @websocket.send({op: 1, d: 0}.to_json)
          sleep heartbeat_interval.milliseconds
        end
      end
    end

    private def identify
      packet = {
        op: 2,
        d:  {
          token:      @token,
          properties: {
            :"$os"               => "Crystal",
            :"$browser"          => "discordcr",
            :"$device"           => "discordcr",
            :"$referrer"         => "",
            :"$referring_domain" => "",
          },
          compress:        false,
          large_threshold: 100,
        },
      }.to_json
      @websocket.send(packet)
    end

    private def handle_dispatch(type, data)
      case type
      when "READY"
        payload = Gateway::ReadyPayload.from_json(data)
        puts "Received READY, v: #{payload.v}"
      when "MESSAGE_CREATE"
        payload = Message.from_json(data)
        puts "Received message with content #{payload.content}"
        @on_message.try &.call(payload)
      else
        puts "Unsupported dispatch: #{type} #{data}"
      end
    end

    def on_message(&@on_message : Message ->)
    end
  end

  struct GatewayPacket
    getter opcode, sequence, data, event_type

    def initialize(@opcode : Int64 | Nil, @sequence : Int64 | Nil, @data : MemoryIO, @event_type : String | Nil)
    end
  end
end
