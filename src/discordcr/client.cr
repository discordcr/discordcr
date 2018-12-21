require "json"

require "logger"
require "./rest"
require "./cache"

module Discord
  # Calculates the shard ID that would receive the gateway events from
  # a guild with the given `guild_id`, based on the total number of shards.
  def self.shard_id(guild_id : UInt64 | Snowflake, total_shards : Int32)
    (guild_id.to_u64 >> 22) % total_shards
  end

  # The basic client class that is used to connect to Discord, send REST
  # requests, or send or receive gateway messages. It is required for doing any
  # sort of interaction with Discord.
  #
  # A new simple client that does nothing yet can be created like this:
  # ```
  # client = Discord::Client.new(token: "Bot token", client_id: 123_u64)
  # ```
  #
  # With this client, REST requests can now be sent. (See the `Discord::REST`
  # module.) A gateway connection can also be started using the `#run` method.
  class Client
    include REST

    # If this is set to any `Cache`, the data in the cache will be updated as
    # the client receives the corresponding gateway dispatches.
    property cache : Cache?

    # The internal *session* the client is currently using, necessary to create
    # a voice client, for example
    getter session : Gateway::Session?

    # The internal websocket the client is currently using
    getter websocket : Discord::WebSocket do
      initialize_websocket
    end

    @backoff : Float64

    # Default analytics properties sent in IDENTIFY
    DEFAULT_PROPERTIES = Gateway::IdentifyProperties.new(
      os: "Crystal",
      browser: "discordcr",
      device: "discordcr",
      referrer: "",
      referring_domain: ""
    )

    # Available gateway compression modes that can be requested
    enum CompressMode
      # Discord won't send any compressed data
      None

      # Large payloads (typically `GUILD_CREATE`) will be received compressed
      Large

      # All data will be received in a compressed stream
      Stream
    end

    # Creates a new bot with the given *token* and optionally the *client_id*.
    # Both of these things can be found on a bot's application page; the token
    # will need to be revealed using the "click to reveal" thing on the token
    # (**not** the OAuth2 secret!)
    #
    # If the *shard* key is set, the gateway will operate in sharded mode. This
    # means that this client's gateway connection will only receive packets from
    # a part of the guilds the bot is connected to. See
    # [here](https://discordapp.com/developers/docs/topics/gateway#sharding)
    # for more information.
    #
    # The *large_threshold* defines the minimum member count that, if a guild
    # has at least that many members, the client will only receive online
    # members in GUILD_CREATE. The default value 100 is what the Discord client
    # uses; the maximum value is 250. To get a list of offline members as well,
    # the `#request_guild_members` method can be used.
    #
    # `compress` can be set to any value of `CompressMode`. `CompressMode::Stream`
    # is the default and will save the most bandwidth. You can optionally change
    # this to `CompressMode::Large` to request that only large payloads be received
    # compressed. Compression can be disabled with `CompressMode::None`, but this
    # is not recommended for production bots.
    #
    # When using `Compress::Stream` compression, the buffer size can be configured
    # by passing `zlib_buffer_size`.
    #
    # The *properties* define what values are sent to Discord as analytics
    # properties. It's not recommended to change these from the default values,
    # but if you desire to do so, you can.
    def initialize(@token : String, @client_id : UInt64 | Snowflake | Nil = nil,
                   @shard : Gateway::ShardKey? = nil,
                   @large_threshold : Int32 = 100,
                   @compress : CompressMode = CompressMode::Stream,
                   @zlib_buffer_size : Int32 = 10 * 1024 * 1024,
                   @properties : Gateway::IdentifyProperties = DEFAULT_PROPERTIES,
                   @logger = Logger.new(STDOUT))
      @logger.progname = "discordcr"
      @backoff = 1.0

      # Set some default value for the heartbeat interval. This should never
      # actually be used as a delay between heartbeats because it will have an
      # actual value before heartbeating starts.
      @heartbeat_interval = 1000_u32
      @send_heartbeats = false

      # Initially, this flag is set to true so the client doesn't immediately
      # try to reconnect at the next heartbeat.
      @last_heartbeat_acked = true

      # If the websocket is closed, whether we should immediately try and reconnect
      @should_reconnect = true
      @client_name = shard ? "Client #{shard}" : "Client"

      setup_heartbeats
    end

    # Returns this client's ID as provided in its associated Oauth2 application.
    # A getter for @client_id, this will make a REST call to obtain it
    # if it was not provided in the initializer.
    def client_id
      @client_id ||= get_oauth2_application.id
    end

    # Connects this client to the gateway. This is required if the bot needs to
    # do anything beyond making REST API calls. Calling this method will block
    # execution until the bot is forcibly stopped.
    def run
      loop do
        begin
          websocket.run
        rescue ex
          @logger.error <<-LOG
            [#{@client_name}] Received exception from WebSocket#run:
            #{ex.inspect_with_backtrace}
            LOG
        end

        @send_heartbeats = false
        @session.try &.suspend

        break unless @should_reconnect

        wait_for_reconnect

        @logger.info "[#{@client_name}] Reconnecting"
        @websocket = initialize_websocket
      end
    end

    # Closes the gateway connection permanently
    def stop(message = nil)
      @should_reconnect = false
      websocket.close(message)
    end

    # Separate method to wait an ever-increasing amount of time before reconnecting after being disconnected in an
    # unexpected way
    def wait_for_reconnect
      # Wait before reconnecting so we don't spam Discord's servers.
      @logger.debug "[#{@client_name}] Attempting to reconnect in #{@backoff} seconds."
      sleep @backoff.seconds

      # Calculate new backoff
      @backoff = 1.0 if @backoff < 1.0
      @backoff *= 1.5
      @backoff = 115 + (rand * 10) if @backoff > 120 # Cap the backoff at 120 seconds and then add some random jitter
    end

    private def initialize_websocket : Discord::WebSocket
      url = URI.parse(get_gateway.url)

      if @compress.stream?
        path = "#{url.path}/?encoding=json&v=6&compress=zlib-stream"
      else
        path = "#{url.path}/?encoding=json&v=6"
      end

      websocket = Discord::WebSocket.new(
        host: url.host.not_nil!,
        path: path,
        port: 443,
        tls: true,
        logger: @logger,
        zlib_buffer_size: @zlib_buffer_size
      )

      websocket.on_message(&->on_message(Discord::WebSocket::Packet))

      case @compress
      when .large?
        websocket.on_compressed(&->on_message(Discord::WebSocket::Packet))
      when .stream?
        websocket.on_compressed_stream(&->on_message(Discord::WebSocket::Packet))
      end

      websocket.on_close(&->on_close(String))

      websocket
    end

    private def on_close(message : String)
      # TODO: make more sophisticated
      @logger.warn "[#{@client_name}] Closed with: " + message

      @send_heartbeats = false
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

    private def on_message(packet : Discord::WebSocket::Packet)
      spawn do
        begin
          case packet.opcode
          when OP_HELLO
            payload = Gateway::HelloPayload.from_json(packet.data)
            handle_hello(payload.heartbeat_interval)
          when OP_DISPATCH
            handle_dispatch(packet.event_type.not_nil!, packet.data)
          when OP_RECONNECT
            handle_reconnect
          when OP_INVALID_SESSION
            handle_invalid_session
          when OP_HEARTBEAT
            # We got a received heartbeat, reply with the same sequence
            @logger.debug "[#{@client_name}] Heartbeat received"
            websocket.send({op: 1, d: packet.sequence}.to_json)
          when OP_HEARTBEAT_ACK
            handle_heartbeat_ack
          else
            @logger.warn "[#{@client_name}] Unsupported payload: #{packet}"
          end
        rescue ex : JSON::ParseException
          @logger.error <<-LOG
            [#{@client_name}] An exception occurred during message parsing! Please report this.
            #{ex.inspect_with_backtrace}
            (pertaining to previous exception) Raised with packet:
            #{packet}
            LOG
        rescue ex
          @logger.error <<-LOG
            [#{@client_name}] A miscellaneous exception occurred during message handling.
            #{ex.inspect_with_backtrace}
            LOG
        end

        # Set the sequence to confirm that we have handled this packet, in case
        # we need to resume
        seq = packet.sequence
        @session.try &.sequence = seq if seq
      end

      nil
    end

    # Injects a *packet* into the packet handler.
    def inject(packet : Discord::WebSocket::Packet)
      on_message(packet)
    end

    private def handle_hello(heartbeat_interval)
      @heartbeat_interval = heartbeat_interval
      @send_heartbeats = true
      @last_heartbeat_acked = true

      # If it seems like we can resume, we will - worst case we get an op9
      if @session.try &.should_resume?
        resume
      else
        identify
      end
    end

    private def setup_heartbeats
      spawn do
        loop do
          if @send_heartbeats
            unless @last_heartbeat_acked
              @logger.warn "[#{@client_name}] Last heartbeat not acked, reconnecting"

              # Give the new connection another chance by resetting the last
              # acked flag; otherwise it would try to reconnect again at the
              # first heartbeat
              @last_heartbeat_acked = true

              reconnect(should_suspend: true)
              next
            end

            @logger.debug "[#{@client_name}] Sending heartbeat"

            begin
              seq = @session.try &.sequence || 0
              websocket.send({op: 1, d: seq}.to_json)
              @last_heartbeat_acked = false
            rescue ex
              @logger.error <<-LOG
                [#{@client_name}] Heartbeat failed!
                #{ex.inspect_with_backtrace}
                LOG
            end
          end

          sleep @heartbeat_interval.milliseconds
        end
      end
    end

    private def identify
      if shard = @shard
        shard_tuple = shard.values
      end

      compress = @compress.large?
      packet = Gateway::IdentifyPacket.new(@token, @properties, compress, @large_threshold, shard_tuple)
      websocket.send(packet.to_json)
    end

    # Sends a resume packet from the given *sequence* number, or alternatively
    # the current session's last received sequence if none is given. This will
    # make Discord replay all events since that sequence.
    def resume(sequence : Int64? = nil)
      session = @session.not_nil!
      sequence ||= session.sequence

      packet = Gateway::ResumePacket.new(@token, session.session_id, sequence)
      websocket.send(packet.to_json)
    end

    # Reconnects the websocket connection entirely. If *should_suspend* is set,
    # the session will be suspended, which means (unless other factors prevent
    # this) that the session will be resumed after reconnection. If
    # *backoff_override* is set to anything other than `nil`, the reconnection
    # backoff will not use the standard formula and instead wait the value
    # provided; use `0.0` to skip waiting entirely.
    def reconnect(should_suspend = false, backoff_override = nil)
      @backoff = backoff_override if backoff_override
      @send_heartbeats = false
      websocket.close

      # Suspend the session so we resume, if desired
      @session.try &.suspend if should_suspend
    end

    # Sends a status update to Discord. The *status* can be `"online"`,
    # `"idle"`, `"dnd"`, or `"invisible"`. Setting the *game* to a `GamePlaying`
    # object makes the bot appear as playing some game on Discord. *since* and
    # *afk* can be used in conjunction to signify to Discord that the status
    # change is due to inactivity on the bot's part – this fulfills no cosmetic
    # purpose.
    def status_update(status : String? = nil, game : GamePlaying? = nil, afk : Bool = false, since : Int64? = nil)
      packet = Gateway::StatusUpdatePacket.new(status, game, afk, since)
      websocket.send(packet.to_json)
    end

    # Sends a voice state update to Discord. This will create a new voice
    # connection on the given *guild_id* and *channel_id*, update an existing
    # one with new *self_mute* and *self_deaf* status, or disconnect from voice
    # if the *channel_id* is `nil`.
    #
    # discordcr doesn't support sending or receiving any data from voice
    # connections yet - this will have to be done externally until that happens.
    def voice_state_update(guild_id : UInt64, channel_id : UInt64?, self_mute : Bool, self_deaf : Bool)
      packet = Gateway::VoiceStateUpdatePacket.new(guild_id, channel_id, self_mute, self_deaf)
      websocket.send(packet.to_json)
    end

    # Requests a full list of members to be sent for a specific guild. This is
    # necessary to get the entire members list for guilds considered large (what
    # is considered large can be changed using the large_threshold parameter
    # in `#initialize`).
    #
    # The list will arrive in the form of GUILD_MEMBERS_CHUNK dispatch events,
    # which can be listened to using `#on_guild_members_chunk`. If a cache
    # is set up, arriving members will be cached automatically.
    def request_guild_members(guild_id : UInt64, query : String = "", limit : Int32 = 0)
      packet = Gateway::RequestGuildMembersPacket.new(guild_id, query, limit)
      websocket.send(packet.to_json)
    end

    # :nodoc:
    macro call_event(name, payload)
      @on_{{name}}_handlers.try &.each do |handler|
        begin
          handler.call({{payload}})
        rescue ex
          @logger.error <<-LOG
            [#{@client_name}] An exception occurred in a user-defined event handler!
            #{ex.inspect_with_backtrace}
            LOG
        end
      end
    end

    # :nodoc:
    macro cache(object)
      @cache.try &.cache {{object}}
    end

    private def handle_dispatch(type, data)
      call_event dispatch, {type, data}

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

        @logger.info "[#{@client_name}] Received READY, v: #{payload.v}"
        call_event ready, payload
      when "RESUMED"
        # RESUMED also means a connection was achieved, so reset the
        # reconnection backoff here too
        @backoff = 1.0

        payload = Gateway::ResumedPayload.from_json(data)
        call_event resumed, payload
      when "CHANNEL_CREATE"
        payload = Channel.from_json(data)

        cache payload
        guild_id = payload.guild_id
        recipients = payload.recipients
        if guild_id
          @cache.try &.add_guild_channel(guild_id, payload.id)
        elsif payload.type.dm? && recipients
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
      when "CHANNEL_PINS_UPDATE"
        payload = Gateway::ChannelPinsUpdatePayload.from_json(data)
        call_event channel_pins_update, payload
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

        payload.members.each do |member|
          cache member.user
          @cache.try &.cache(member, guild.id)
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
      when "GUILD_EMOJIS_UPDATE"
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
          new_member = GuildMember.new(member, payload.roles, payload.nick)
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

        cache payload.author
        guild_id = payload.guild_id
        partial_member = payload.member
        if guild_id && partial_member
          member = GuildMember.new(payload.author, partial_member)
          @cache.try &.cache(member, guild_id)
        end

        call_event message_create, payload
      when "MESSAGE_REACTION_ADD"
        payload = Gateway::MessageReactionPayload.from_json(data)
        call_event message_reaction_add, payload
      when "MESSAGE_REACTION_REMOVE"
        payload = Gateway::MessageReactionPayload.from_json(data)
        call_event message_reaction_remove, payload
      when "MESSAGE_REACTION_REMOVE_ALL"
        payload = Gateway::MessageReactionRemoveAllPayload.from_json(data)
        call_event message_reaction_remove_all, payload
      when "MESSAGE_UPDATE"
        payload = Gateway::MessageUpdatePayload.from_json(data)
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

        guild_id = payload.guild_id
        member = payload.member
        if guild_id && member
          @cache.try &.cache(member, guild_id)
        end

        call_event typing_start, payload
      when "USER_UPDATE"
        payload = User.from_json(data)
        call_event user_update, payload
      when "VOICE_STATE_UPDATE"
        payload = VoiceState.from_json(data)

        guild_id = payload.guild_id
        member = payload.member
        if guild_id && member
          @cache.try &.cache(member, guild_id)
        end

        call_event voice_state_update, payload
      when "VOICE_SERVER_UPDATE"
        payload = Gateway::VoiceServerUpdatePayload.from_json(data)
        call_event voice_server_update, payload
      when "WEBHOOKS_UPDATE"
        payload = Gateway::WebhooksUpdatePayload.from_json(data)
        call_event webhooks_update, payload
      else
        @logger.warn "[#{@client_name}] Unsupported dispatch: #{type} #{data}"
      end
    end

    private def handle_reconnect
      # We want the reconnection to happen instantly, and we want a resume to be
      # attempted, so set the respective parameters
      reconnect(should_suspend: true, backoff_override: 0.0)
    end

    private def handle_invalid_session
      @session.try &.invalidate
      identify
    end

    private def handle_heartbeat_ack
      @logger.debug "[#{@client_name}] Heartbeat ACK received"
      @last_heartbeat_acked = true
    end

    # :nodoc:
    macro event(name, payload_type)
      def on_{{name}}(&handler : {{payload_type}} ->)
        (@on_{{name}}_handlers ||= [] of {{payload_type}} ->) << handler
      end
    end

    # Called when the bot receives any kind of dispatch at all, even one that
    # is otherwise unsupported. This can be useful for statistics, e. g. how
    # many gateway events are received per second. It can also be useful to
    # handle new API changes not yet supported by the lib.
    #
    # The parameter passed to the event will be a tuple of `{type, data}`, where
    # `type` is the event type (e.g. "MESSAGE_CREATE") and `data` is the
    # unprocessed JSON event data.
    event dispatch, {String, IO::Memory}

    # Called when the bot has successfully initiated a session with Discord. It
    # marks the point when gateway packets can be set (e. g. `#status_update`).
    #
    # Note that this event may be called multiple times over the course of a
    # bot lifetime, as it is also called when the client reconnects with a new
    # session.
    #
    # [API docs for this event](https://discordapp.com/developers/docs/topics/gateway#ready)
    event ready, Gateway::ReadyPayload

    # Called when the client has successfully resumed an existing connection
    # after reconnecting.
    #
    # [API docs for this event](https://discordapp.com/developers/docs/topics/gateway#resumed)
    event resumed, Gateway::ResumedPayload

    # Called when a channel has been created on a server the bot has access to,
    # or when somebody has started a DM channel with the bot.
    #
    # [API docs for this event](https://discordapp.com/developers/docs/topics/gateway#channel-create)
    event channel_create, Channel

    # Called when a channel's properties are updated, like the name or
    # permission overwrites.
    #
    # [API docs for this event](https://discordapp.com/developers/docs/topics/gateway#channel-update)
    event channel_update, Channel

    # Called when a channel the bot has access to is deleted. This is not called
    # for other users closing the DM channel with the bot, only for the bot
    # closing the DM channel with a user.
    #
    # [API docs for this event](https://discordapp.com/developers/docs/topics/gateway#channel-delete)
    event channel_delete, Channel

    # Called when a channel's pinned messages are updated, where a pin was
    # either added or removed.
    #
    # [API docs for this event](https://discordapp.com/developers/docs/topics/gateway#channel-pins-update)
    event channel_pins_update, Gateway::ChannelPinsUpdatePayload

    # Called when the bot is added to a guild, a guild unavailable due to an
    # outage becomes available again, or the guild is streamed after READY.
    # To verify that it is the first case, you can check the `unavailable`
    # property in `Gateway::GuildCreatePayload`.
    #
    # [API docs for this event](https://discordapp.com/developers/docs/topics/gateway#guild-create)
    event guild_create, Gateway::GuildCreatePayload

    # Called when a guild's properties, like name or verification level, are
    # updated.
    #
    # [API docs for this event](https://discordapp.com/developers/docs/topics/gateway#guild-update)
    event guild_update, Guild

    # Called when the bot leaves a guild or a guild becomes unavailable due to
    # an outage. To verify that it is the former case, you can check the
    # `unavailable` property.
    #
    # [API docs for this event](https://discordapp.com/developers/docs/topics/gateway#guild-delete)
    event guild_delete, Gateway::GuildDeletePayload

    # Called when somebody is banned from a guild. A `#on_guild_member_remove`
    # event is also called.
    #
    # [API docs for this event](https://discordapp.com/developers/docs/topics/gateway#guild-ban-add)
    event guild_ban_add, Gateway::GuildBanPayload

    # Called when somebody is unbanned from a guild.
    #
    # [API docs for this event](https://discordapp.com/developers/docs/topics/gateway#guild-ban-remove)
    event guild_ban_remove, Gateway::GuildBanPayload

    # Called when a guild's emoji are updated.
    #
    # [API docs for this event](https://discordapp.com/developers/docs/topics/gateway#guild-emoji-update)
    event guild_emoji_update, Gateway::GuildEmojiUpdatePayload

    # Called when a guild's integrations (Twitch, YouTube) are updated.
    #
    # [API docs for this event](https://discordapp.com/developers/docs/topics/gateway#guild-integrations-update)
    event guild_integrations_update, Gateway::GuildIntegrationsUpdatePayload

    # Called when somebody other than the bot joins a guild.
    #
    # [API docs for this event](https://discordapp.com/developers/docs/topics/gateway#guild-member-add)
    event guild_member_add, Gateway::GuildMemberAddPayload

    # Called when a member object is updated. This happens when somebody
    # changes their nickname or has their roles changed.
    #
    # [API docs for this event](https://discordapp.com/developers/docs/topics/gateway#guild-member-update)
    event guild_member_update, Gateway::GuildMemberUpdatePayload

    # Called when somebody other than the bot leaves a guild.
    #
    # [API docs for this event](https://discordapp.com/developers/docs/topics/gateway#guild-member-remove)
    event guild_member_remove, Gateway::GuildMemberRemovePayload

    # Called when Discord sends a chunk of member objects after a
    # `#request_guild_members` call. If a `Cache` is set up, this is handled
    # automatically.
    #
    # [API docs for this event](https://discordapp.com/developers/docs/topics/gateway#guild-members-chunk)
    event guild_members_chunk, Gateway::GuildMembersChunkPayload

    # Called when a role is created on a guild.
    #
    # [API docs for this event](https://discordapp.com/developers/docs/topics/gateway#guild-role-create)
    event guild_role_create, Gateway::GuildRolePayload

    # Called when a role's properties are updated, for example name or colour.
    #
    # [API docs for this event](https://discordapp.com/developers/docs/topics/gateway#guild-role-update)
    event guild_role_update, Gateway::GuildRolePayload

    # Called when a role is deleted.
    #
    # [API docs for this event](https://discordapp.com/developers/docs/topics/gateway#guild-role-delete)
    event guild_role_delete, Gateway::GuildRoleDeletePayload

    # Called when a message is sent to a channel the bot has access to. This
    # may be any sort of text channel, no matter private or guild.
    #
    # [API docs for this event](https://discordapp.com/developers/docs/topics/gateway#message-create)
    event message_create, Message

    # Called when a reaction is added to a message.
    event message_reaction_add, Gateway::MessageReactionPayload

    # Called when a reaction is removed from a message.
    event message_reaction_remove, Gateway::MessageReactionPayload

    # Called when all reactions are removed at once from a message.
    event message_reaction_remove_all, Gateway::MessageReactionRemoveAllPayload

    # Called when a message is updated. Most commonly this is done for edited
    # messages, but the event is also sent when embed information for an
    # existing message is updated.
    #
    # [API docs for this event](https://discordapp.com/developers/docs/topics/gateway#message-update)
    event message_update, Gateway::MessageUpdatePayload

    # Called when a single message is deleted.
    #
    # [API docs for this event](https://discordapp.com/developers/docs/topics/gateway#message-delete)
    event message_delete, Gateway::MessageDeletePayload

    # Called when multiple messages are deleted at once, due to a bot using the
    # bulk_delete endpoint.
    #
    # [API docs for this event](https://discordapp.com/developers/docs/topics/gateway#message-delete-bulk)
    event message_delete_bulk, Gateway::MessageDeleteBulkPayload

    # Called when a user updates their status (online/idle/offline), the game
    # they are playing, or their streaming status. Also called when a user's
    # properties (user/avatar/discriminator) are changed.
    #
    # [API docs for this event](https://discordapp.com/developers/docs/topics/gateway#presence-update)
    event presence_update, Gateway::PresenceUpdatePayload

    # Called when somebody starts typing in a channel the bot has access to.
    #
    # [API docs for this event](https://discordapp.com/developers/docs/topics/gateway#typing-start)
    event typing_start, Gateway::TypingStartPayload

    # Called when the user properties of the bot itself are changed.
    #
    # [API docs for this event](https://discordapp.com/developers/docs/topics/gateway#user-update)
    event user_update, User

    # Called when somebody joins or leaves a voice channel, moves to a different
    # one, or is muted/unmuted/deafened/undeafened.
    #
    # [API docs for this event](https://discordapp.com/developers/docs/topics/gateway#voice-state-update)
    event voice_state_update, VoiceState

    # Called when a guild's voice server changes. This event is called with
    # the current voice server when initially connecting to voice, and it is
    # called again with the new voice server when the current server fails over
    # to a new one, or when the guild's voice region changes.
    #
    # [API docs for this event](https://discordapp.com/developers/docs/topics/gateway#voice-server-update)
    event voice_server_update, Gateway::VoiceServerUpdatePayload

    # Sent when a guild channel's webhook is created, updated, or deleted.
    #
    # [API docs for this event](https://discordapp.com/developers/docs/topics/gateway#webhooks-update)
    event webhooks_update, Gateway::WebhooksUpdatePayload
  end

  module Gateway
    alias ShardKey = {shard_id: Int32, num_shards: Int32}

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
