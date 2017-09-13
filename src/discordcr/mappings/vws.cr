require "./converters"

module Discord
  # :nodoc:
  module VWS
    struct IdentifyPacket
      def initialize(server_id, user_id, session_id, token)
        @op = Discord::VoiceClient::OP_IDENTIFY
        @d = IdentifyPayload.new(server_id, user_id, session_id, token)
      end

      JSON.mapping(
        op: Int32,
        d: IdentifyPayload
      )
    end

    struct IdentifyPayload
      def initialize(@server_id, @user_id, @session_id, @token)
      end

      JSON.mapping(
        server_id: UInt64,
        user_id: UInt64,
        session_id: String,
        token: String
      )
    end

    struct SelectProtocolPacket
      def initialize(protocol, data)
        @op = Discord::VoiceClient::OP_SELECT_PROTOCOL
        @d = SelectProtocolPayload.new(protocol, data)
      end

      JSON.mapping(
        op: Int32,
        d: SelectProtocolPayload
      )
    end

    struct SelectProtocolPayload
      def initialize(@protocol, @data)
      end

      JSON.mapping(
        protocol: String,
        data: ProtocolData
      )
    end

    struct ProtocolData
      def initialize(@address, @port, @mode)
      end

      JSON.mapping(
        address: String,
        port: UInt16,
        mode: String
      )
    end

    struct ReadyPayload
      JSON.mapping(
        ssrc: Int32,
        port: Int32,
        modes: Array(String),
        heartbeat_interval: Int32
      )
    end

    struct SessionDescriptionPayload
      JSON.mapping(
        secret_key: Array(UInt8)
      )
    end

    struct SpeakingPacket
      def initialize(speaking, delay)
        @op = Discord::VoiceClient::OP_SPEAKING
        @d = SpeakingPayload.new(speaking, delay)
      end

      JSON.mapping(
        op: Int32,
        d: SpeakingPayload
      )
    end

    struct SpeakingPayload
      def initialize(@speaking, @delay)
      end

      JSON.mapping(
        speaking: Bool,
        delay: Int32
      )
    end

    struct HelloPayload
      JSON.mapping(
        heartbeat_interval: Int32
      )
    end
  end
end
