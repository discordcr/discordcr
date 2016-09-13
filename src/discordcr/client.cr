require "http/web_socket"
require "json"

require "./rest"
require "./cache"

module Discord
  class Client
    include REST

    property cache : Cache?

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

  # :nodoc:
  struct GatewayPacket
    getter opcode, sequence, data, event_type

    def initialize(@opcode : Int64 | Nil, @sequence : Int64 | Nil, @data : MemoryIO, @event_type : String | Nil)
    end
  end
end
