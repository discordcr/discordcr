require "http"

module Discord
  # Internal wrapper around HTTP::WebSocket to decode the Discord-specific
  # payload format used in the gateway and VWS.
  class WebSocket
    # :nodoc:
    struct Packet
      getter opcode, sequence, data, event_type

      def initialize(@opcode : Int64?, @sequence : Int64?, @data : IO::Memory, @event_type : String?)
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

    def on_message(&handler : Packet ->)
      @websocket.on_message do |message|
        @logger.debug "[WS IN] #{message}" if @logger.debug?
        payload = parse_message(message)
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

    private def parse_message(message : String)
      parser = JSON::PullParser.new(message)

      opcode = nil
      sequence = nil
      event_type = nil
      data = IO::Memory.new

      parser.read_object do |key|
        case key
        when "op"
          opcode = parser.read_int
        when "d"
          # Read the raw JSON into memory
          JSON.build(data) do |builder|
            parser.read_raw(builder)
          end
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

      Packet.new(opcode, sequence, data, event_type)
    end
  end
end
