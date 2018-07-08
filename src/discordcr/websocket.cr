require "http"
require "json"
require "zlib"

module Discord
  # Internal wrapper around HTTP::WebSocket to decode the Discord-specific
  # payload format used in the gateway and VWS.
  class WebSocket
    # :nodoc:
    struct Packet
      include JSON::Serializable

      module DataConverter
        def self.from_json(parser)
          data = IO::Memory.new
          JSON.build(data) do |builder|
            parser.read_raw(builder)
          end
          data.rewind
        end

        def self.to_json(value, builder)
          builder.raw(value.to_s)
        end
      end

      @[JSON::Field(key: "op")]
      getter opcode : Int64

      @[JSON::Field(key: "s")]
      getter sequence : Int64?

      @[JSON::Field(key: "d", converter: Discord::WebSocket::Packet::DataConverter)]
      getter data : IO::Memory

      @[JSON::Field(key: "t")]
      getter event_type : String?

      def initialize(@opcode : Int64, @sequence : Int64?, @data : IO::Memory, @event_type : String?)
      end

      def inspect(io : IO)
        io << "Discord::WebSocket::Packet(@opcode="
        opcode.inspect(io)
        io << " @sequence="
        sequence.inspect(io)
        io << " @data="
        data.to_s.inspect(io)
        io << " @event_type="
        event_type.inspect(io)
        io << ')'
      end
    end

    def initialize(@host : String, @path : String, @port : Int32, @tls : Bool, @logger : Logger)
      @websocket = HTTP::WebSocket.new(
        host: @host,
        path: @path,
        port: @port,
        tls: @tls
      )
    end

    def on_binary(&handler : Packet ->)
      @websocket.on_binary do |binary|
        io = IO::Memory.new(binary)
        Zlib::Reader.open(io) do |reader|
          payload = Packet.from_json(reader)
          @logger.debug "[WS IN] (compressed, #{binary.size}) #{payload.to_json}"
          handler.call(payload)
        end
      end
    end

    def on_message(&handler : Packet ->)
      @websocket.on_message do |message|
        @logger.debug "[WS IN] #{message}" if @logger.debug?
        payload = Packet.from_json(message)
        handler.call(payload)
      end
    end

    def on_close(&handler : String ->)
      @websocket.on_close(&handler)
    end

    delegate run, close, to: @websocket

    def send(message)
      @logger.debug "[WS OUT] #{message}" if @logger.debug?
      @websocket.send(message)
    end
  end
end
