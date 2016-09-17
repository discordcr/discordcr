require "http/web_socket"
require "json"

require "./rest"
require "./cache"

module Discord
  class Client
    include REST

    property cache : Cache?

    @websocket : HTTP::WebSocket

    def initialize(@token : String, @client_id : UInt64)
      @websocket = initialize_websocket
      @backoff = 1.0
    end

    def run
      loop do
        @websocket.run

        wait_for_reconnect

        puts "Reconnecting"
        @websocket = initialize_websocket
      end
    end

    # Separate method to wait an ever-increasing amount of time before reconnecting after being disconnected in an
    # unexpected way
    def wait_for_reconnect
      # Wait before reconnecting so we don't spam Discord's servers.
      puts "Attempting to reconnect in #{@backoff} seconds."
      sleep @backoff.seconds

      # Calculate new backoff
      @backoff = 1.0 if @backoff < 1.0
      @backoff *= 1.5
      @backoff = 115 + (rand * 10) if @backoff > 120 # Cap the backoff at 120 seconds and then add some random jitter
    end

    private def initialize_websocket : HTTP::WebSocket
      url = URI.parse(get_gateway.url)
      websocket = HTTP::WebSocket.new(
        host: url.host.not_nil!,
        path: "#{url.path}/?encoding=json&v=6",
        port: 443,
        tls: true
      )

      websocket.on_message(&->on_message(String))
      websocket.on_close(&->on_close(String))

      websocket
    end

    private def on_close(message : String)
      # TODO: make more sophisticated
      puts "Closed with: " + message

      @session.try &.suspend
      nil
    end

    OP_DISPATCH              =  0
    OP_HEARTBEAT             =  1
    OP_IDENTIFY              =  2
    OP_STATUS_UPDATE         =  3
    OP_VOICE_STATE_UPDATE    =  4
    OP_VOICE_SERVER_PING     =  5
    OP_RESUME                =  6
    OP_RECONNECT             =  7
    OP_REQUEST_GUILD_MEMBERS =  8
    OP_INVALID_SESSION       =  9
    OP_HELLO                 = 10
    OP_HEARTBEAT_ACK         = 11

    private def on_message(message : String)
      spawn do
        packet = parse_message(message)

        case packet.opcode
        when OP_HELLO
          payload = Gateway::HelloPayload.from_json(packet.data)
          handle_hello(payload.heartbeat_interval)
        when OP_DISPATCH
          handle_dispatch(packet.event_type, packet.data)
        when OP_RECONNECT
          handle_reconnect
        when OP_INVALID_SESSION
          handle_invalid_session
        else
          puts "Unsupported message: #{message}"
        end

        # Set the sequence to confirm that we have handled this packet, in case
        # we need to resume
        seq = packet.sequence
        @session.try &.sequence = seq if seq
      end

      nil
    end

    # Injects a JSON *message* into the packet handler. Must be a valid gateway
    # packet, including opcode, sequence and type.
    def inject(message)
      on_message(message)
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

      Gateway::GatewayPacket.new(opcode, sequence, data, event_type)
    end

    private def handle_hello(heartbeat_interval)
      setup_heartbeats(heartbeat_interval)

      # If it seems like we can resume, we will - worst case we get an op9
      if @session.try &.should_resume?
        resume
      else
        identify
      end
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

    # Sends a resume packet from the given *sequence* number, or alternatively
    # the current session's last received sequence if none is given. This will
    # make Discord replay all events since that sequence.
    def resume(sequence : Int64? = nil)
      session = @session.not_nil!
      sequence ||= session.sequence

      packet = Gateway::ResumePacket.new(@token, session.session_id, sequence)
      @websocket.send(packet.to_json)
    end

    # :nodoc:
    macro call_event(name, payload)
      @on_{{name}}_handlers.try &.each { |handler| handler.call({{payload}}) }
    end

    # :nodoc:
    macro cache(object)
      @cache.try &.cache {{object}}
    end

    private def handle_dispatch(type, data)
      case type
      when "READY"
        payload = Gateway::ReadyPayload.from_json(data)

        @session = Gateway::Session.new(payload.session_id)

        # Reset the backoff, because READY means we successfully achieved a
        # connection and don't have to wait next time
        @backoff = 1.0

        @cache.try &.cache_current_user(payload.user)

        payload.private_channels.each do |channel|
          cache Channel.new(channel)

          if channel.type == 1 # DM channel, not group
            recipient_id = channel.recipients[0].id
            @cache.try &.cache_dm_channel(channel.id, recipient_id)
          end
        end

        puts "Received READY, v: #{payload.v}"
        call_event ready, payload
      when "CHANNEL_CREATE"
        payload = Channel.from_json(data)

        cache payload
        guild_id = payload.guild_id
        recipients = payload.recipients
        if guild_id
          @cache.try &.add_guild_channel(guild_id, payload.id)
        elsif payload.type == 1 && recipients
          @cache.try &.cache_dm_channel(payload.id, recipients[0].id)
        end

        call_event channel_create, payload
      when "CHANNEL_UPDATE"
        payload = Channel.from_json(data)

        cache payload

        call_event channel_update, payload
      when "CHANNEL_DELETE"
        payload = Channel.from_json(data)

        @cache.try &.delete_channel(payload.id)
        guild_id = payload.guild_id
        @cache.try &.remove_guild_channel(guild_id, payload.id) if guild_id

        call_event channel_delete, payload
      when "GUILD_CREATE"
        payload = Gateway::GuildCreatePayload.from_json(data)

        guild = Guild.new(payload)
        cache guild

        payload.channels.each do |channel|
          channel.guild_id = guild.id
          cache channel
          @cache.try &.add_guild_channel(guild.id, channel.id)
        end

        payload.roles.each do |role|
          cache role
          @cache.try &.add_guild_role(guild.id, role.id)
        end

        call_event guild_create, payload
      when "GUILD_UPDATE"
        payload = Guild.from_json(data)

        cache payload

        call_event guild_update, payload
      when "GUILD_DELETE"
        payload = Gateway::GuildDeletePayload.from_json(data)

        @cache.try &.delete_guild(payload.id)

        call_event guild_delete, payload
      when "GUILD_BAN_ADD"
        payload = Gateway::GuildBanPayload.from_json(data)
        call_event guild_ban_add, payload
      when "GUILD_BAN_REMOVE"
        payload = Gateway::GuildBanPayload.from_json(data)
        call_event guild_ban_remove, payload
      when "GUILD_EMOJI_UPDATE"
        payload = Gateway::GuildEmojiUpdatePayload.from_json(data)
        call_event guild_emoji_update, payload
      when "GUILD_INTEGRATIONS_UPDATE"
        payload = Gateway::GuildIntegrationsUpdatePayload.from_json(data)
        call_event guild_integrations_update, payload
      when "GUILD_MEMBER_ADD"
        payload = Gateway::GuildMemberAddPayload.from_json(data)

        cache payload.user
        member = GuildMember.new(payload)
        @cache.try &.cache(member, payload.guild_id)

        call_event guild_member_add, payload
      when "GUILD_MEMBER_UPDATE"
        payload = Gateway::GuildMemberUpdatePayload.from_json(data)

        cache payload.user
        @cache.try do |c|
          member = c.resolve_member(payload.guild_id, payload.user.id)
          new_member = GuildMember.new(member, payload.roles)
          c.cache(new_member, payload.guild_id)
        end

        call_event guild_member_update, payload
      when "GUILD_MEMBER_REMOVE"
        payload = Gateway::GuildMemberRemovePayload.from_json(data)

        cache payload.user
        @cache.try &.delete_member(payload.guild_id, payload.user.id)

        call_event guild_member_remove, payload
      when "GUILD_MEMBERS_CHUNK"
        payload = Gateway::GuildMembersChunkPayload.from_json(data)

        @cache.try &.cache_multiple_members(payload.members, payload.guild_id)

        call_event guild_members_chunk, payload
      when "GUILD_ROLE_CREATE"
        payload = Gateway::GuildRolePayload.from_json(data)

        cache payload.role
        @cache.try &.add_guild_role(payload.guild_id, payload.role.id)

        call_event guild_role_create, payload
      when "GUILD_ROLE_UPDATE"
        payload = Gateway::GuildRolePayload.from_json(data)

        cache payload.role

        call_event guild_role_update, payload
      when "GUILD_ROLE_DELETE"
        payload = Gateway::GuildRoleDeletePayload.from_json(data)

        @cache.try &.delete_role(payload.role_id)
        @cache.try &.remove_guild_role(payload.guild_id, payload.role_id)

        call_event guild_role_delete, payload
      when "MESSAGE_CREATE"
        payload = Message.from_json(data)
        puts "Received message with content #{payload.content}"
        call_event message_create, payload
      when "MESSAGE_UPDATE"
        payload = Message.from_json(data)
        call_event message_update, payload
      when "MESSAGE_DELETE"
        payload = Gateway::MessageDeletePayload.from_json(data)
        call_event message_delete, payload
      when "MESSAGE_DELETE_BULK"
        payload = Gateway::MessageDeleteBulkPayload.from_json(data)
        call_event message_delete_bulk, payload
      when "PRESENCE_UPDATE"
        payload = Gateway::PresenceUpdatePayload.from_json(data)

        if payload.user.full?
          member = GuildMember.new(payload)
          @cache.try &.cache(member, payload.guild_id)
        end

        call_event presence_update, payload
      when "TYPING_START"
        payload = Gateway::TypingStartPayload.from_json(data)
        call_event typing_start, payload
      when "USER_UPDATE"
        payload = User.from_json(data)
        call_event user_update, payload
      when "VOICE_STATE_UPDATE"
        payload = VoiceState.from_json(data)
        call_event voice_state_update, payload
      when "VOICE_SERVER_UPDATE"
        payload = Gateway::VoiceServerUpdatePayload.from_json(data)
        call_event voice_server_update, payload
      else
        puts "Unsupported dispatch: #{type} #{data}"
      end
    end

    private def handle_reconnect
      # Close the websocket - the reconnection logic will kick in. We want this
      # to happen instantly so set the backoff to 0 seconds
      @backoff = 0.0
      @websocket.close

      # Suspend the session so we 1. resume and 2. don't send heartbeats
      @session.try &.suspend
    end

    private def handle_invalid_session
      @session.try &.invalidate
      identify
    end

    # :nodoc:
    macro event(name, payload_type)
      def on_{{name}}(&handler : {{payload_type}} ->)
        (@on_{{name}}_handlers ||= [] of {{payload_type}} ->) << handler
      end
    end

    event ready, Gateway::ReadyPayload

    event channel_create, Channel
    event channel_update, Channel
    event channel_delete, Channel

    event guild_create, Gateway::GuildCreatePayload
    event guild_update, Guild
    event guild_delete, Gateway::GuildDeletePayload

    event guild_ban_add, Gateway::GuildBanPayload
    event guild_ban_remove, Gateway::GuildBanPayload

    event guild_emoji_update, Gateway::GuildEmojiUpdatePayload
    event guild_integrations_update, Gateway::GuildIntegrationsUpdatePayload

    event guild_member_add, Gateway::GuildMemberAddPayload
    event guild_member_update, Gateway::GuildMemberUpdatePayload
    event guild_member_remove, Gateway::GuildMemberRemovePayload

    event guild_members_chunk, Gateway::GuildMembersChunkPayload

    event guild_role_create, Gateway::GuildRolePayload
    event guild_role_update, Gateway::GuildRolePayload
    event guild_role_delete, Gateway::GuildRoleDeletePayload

    event message_create, Message
    event message_update, Message
    event message_delete, Gateway::MessageDeletePayload
    event message_delete_bulk, Gateway::MessageDeleteBulkPayload

    event presence_update, Gateway::PresenceUpdatePayload
    event typing_start, Gateway::TypingStartPayload

    event user_update, User
    event voice_state_update, VoiceState
    event voice_server_update, Gateway::VoiceServerUpdatePayload
  end

  module Gateway
    # :nodoc:
    struct GatewayPacket
      getter opcode, sequence, data, event_type

      def initialize(@opcode : Int64?, @sequence : Int64?, @data : MemoryIO, @event_type : String?)
      end
    end

    class Session
      getter session_id
      property sequence

      def initialize(@session_id : String)
        @sequence = 0_i64

        @suspended = false
        @invalid = false
      end

      def suspend
        @suspended = true
      end

      def suspended? : Bool
        @suspended
      end

      def invalidate
        @invalid = true
      end

      def invalid? : Bool
        @invalid
      end

      def should_resume? : Bool
        suspended? && !invalid?
      end
    end
  end
end
