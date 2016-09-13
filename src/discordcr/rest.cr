require "http/client"
require "openssl/ssl/context"
require "time/format"

require "./mappings/*"
require "./version"

module Discord
  module REST
    SSL_CONTEXT = OpenSSL::SSL::Context::Client.new
    USER_AGENT  = "DiscordBot (https://github.com/meew0/discordcr, #{Discord::VERSION})"
    API_BASE    = "https://discordapp.com/api/v6"

    alias RateLimitKey = {route_key: Symbol, major_parameter: UInt64?}

    def request(route_key : Symbol, major_parameter : UInt64?, method : String, path : String, headers : HTTP::Headers, body : String?)
      mutexes = @mutexes ||= Hash(RateLimitKey, Mutex).new
      global_mutex = @global_mutex ||= Mutex.new

      headers["Authorization"] = @token
      headers["User-Agent"] = USER_AGENT

      request_done = false
      rate_limit_key = {route_key: route_key, major_parameter: major_parameter}

      until request_done
        mutexes[rate_limit_key] ||= Mutex.new

        # Make sure to catch up with existing mutexes - they may be locked from
        # another fiber.
        mutexes[rate_limit_key].synchronize {}
        global_mutex.synchronize {}

        response = HTTP::Client.exec(method: method, url: API_BASE + path, headers: headers, body: body, tls: SSL_CONTEXT)

        if response.status_code == 429 || response.headers["X-RateLimit-Remaining"]? == "0"
          # We got rate limited!
          if response.headers["Retry-After"]?
            # Retry-After is in ms, convert to seconds first
            retry_after = response.headers["Retry-After"].to_i / 1000.0
          else
            # Calculate the difference between the HTTP Date header, which
            # represents the time the response was sent on Discord's side, and
            # the reset header which represents when the rate limit will get
            # reset.
            origin_time = HTTP.parse_time(response.headers["Date"]).not_nil!
            reset_time = Time.epoch(response.headers["X-RateLimit-Reset"].to_u64) # gotta prevent that Y2k38
            diff = reset_time - origin_time
            retry_after = diff.seconds
          end

          if response.headers["X-RateLimit-Global"]?
            global_mutex.synchronize { sleep retry_after }
          else
            mutexes[rate_limit_key].synchronize { sleep retry_after }
          end

          # If we actually got a 429, i. e. the request failed, we need to
          # retry it.
          request_done = true unless response.status_code == 429
        else
          request_done = true
        end
      end

      response.not_nil!
    end

    def get_gateway
      response = request(
        :gateway,
        nil,
        "GET",
        "/gateway",
        HTTP::Headers.new,
        nil
      )

      GatewayResponse.from_json(response.body)
    end

    def get_channel(channel_id : UInt64)
      response = request(
        :channels_cid,
        channel_id,
        "GET",
        "/channels/#{channel_id}",
        HTTP::Headers.new,
        nil
      )

      Channel.from_json(response.body)
    end

    def modify_channel(channel_id : UInt64, name : String?, position : UInt32?,
                       topic : String?, bitrate : UInt32?, user_limit : UInt32?)
      json = {
        name:       name,
        position:   position,
        topic:      topic,
        bitrate:    bitrate,
        user_limit: user_limit,
      }.to_json

      response = request(
        :channels_cid,
        channel_id,
        "PATCH",
        "/channels/#{channel_id}",
        HTTP::Headers{"Content-Type" => "application/json"},
        json
      )

      Channel.from_json(response.body)
    end

    def delete_channel(channel_id : UInt64)
      response = request(
        :channels_cid,
        channel_id,
        "DELETE",
        "/channels/#{channel_id}",
        HTTP::Headers.new,
        nil
      )
    end

    def get_channel_messages(channel_id : UInt64, limit : UInt8 = 50, before : UInt64? = nil, after : UInt64? = nil, around : UInt64? = nil)
      path = "/channels/#{channel_id}/messages?limit=#{limit}"
      path += "&before=#{before}" if before
      path += "&after=#{after}" if after
      path += "&around=#{around}" if around

      response = request(
        :channels_cid_messages,
        channel_id,
        "GET",
        path,
        HTTP::Headers.new,
        nil
      )

      Array(Message).from_json(response.body)
    end

    def get_channel_message(channel_id : UInt64, message_id : UInt64)
      response = request(
        :channels_cid_messages_mid,
        channel_id,
        "GET",
        "/channels/#{channel_id}/messages/#{message_id}",
        HTTP::Headers.new,
        nil
      )

      Message.from_json(response.body)
    end

    def create_message(channel_id : UInt64, content : String)
      response = request(
        :channels_cid_messages,
        channel_id,
        "POST",
        "/channels/#{channel_id}/messages",
        HTTP::Headers{"Content-Type" => "application/json"},
        {content: content}.to_json
      )

      Message.from_json(response.body)
    end

    # TODO: Add the upload file endpoint when the multipart PR is merged

    def edit_message(channel_id : UInt64, message_id : UInt64, content : String)
      response = request(
        :channels_cid_messages_mid,
        channel_id,
        "PATCH",
        "/channels/#{channel_id}/messages/#{message_id}",
        HTTP::Headers{"Content-Type" => "application/json"},
        {content: content}.to_json
      )

      Message.from_json(response.body)
    end

    def delete_message(channel_id : UInt64, message_id : UInt64)
      response = request(
        :channels_cid_messages_mid,
        channel_id,
        "DELETE",
        "/channels/#{channel_id}/messages/#{message_id}",
        HTTP::Headers.new,
        nil
      )
    end

    def bulk_delete_messages(channel_id : UInt64, message_ids : Array(UInt64))
      response = request(
        :channels_cid_messages_bulk_delete,
        channel_id,
        "POST",
        "/channels/#{channel_id}/messages/bulk_delete",
        HTTP::Headers{"Content-Type" => "application/json"},
        message_ids.to_json
      )
    end

    def edit_channel_permissions(channel_id : UInt64, overwrite_id : UInt64,
                                 type : String, allow : UInt64, deny : UInt64)
      json = {
        allow: allow,
        deny:  deny,
        type:  type,
      }.to_json

      response = request(
        :channels_cid_permissions_oid,
        channel_id,
        "PUT",
        "/channels/#{channel_id}/permissions/#{overwrite_id}",
        HTTP::Headers{"Content-Type" => "application/json"},
        json
      )
    end

    def get_channel_invites(channel_id : UInt64)
      response = request(
        :channels_cid_invites,
        channel_id,
        "GET",
        "/channels/#{channel_id}/invites",
        HTTP::Headers.new,
        nil
      )

      Array(InviteMetadata).from_json(response.body)
    end

    def create_channel_invite(channel_id : UInt64, max_age : UInt32 = 0,
                              max_uses : UInt32 = 0, temporary : Bool = false)
      json = {
        max_age:   max_age,
        max_uses:  max_uses,
        temporary: temporary,
      }.to_json

      response = request(
        :channels_cid_invites,
        channel_id,
        "POST",
        "/channels/#{channel_id}/invites",
        HTTP::Headers{"Content-Type" => "application/json"},
        json
      )

      Invite.from_json(response.body)
    end

    def delete_channel_permission(channel_id : UInt64, overwrite_id : UInt64)
      response = request(
        :channels_cid_permissions_oid,
        channel_id,
        "DELETE",
        "/channels/#{channel_id}/permissions/#{overwrite_id}",
        HTTP::Headers.new,
        nil
      )
    end

    def trigger_typing_indicator(channel_id : UInt64)
      response = request(
        :channels_cid_typing,
        channel_id,
        "POST",
        "/channels/#{channel_id}/typing",
        HTTP::Headers.new,
        nil
      )
    end

    def get_pinned_messages(channel_id : UInt64)
      response = request(
        :channels_cid_pins,
        channel_id,
        "GET",
        "/channels/#{channel_id}/pins",
        HTTP::Headers.new,
        nil
      )

      Array(Message).from_json(response.body)
    end

    def add_pinned_channel_message(channel_id : UInt64, message_id : UInt64)
      response = request(
        :channels_cid_pins_mid,
        channel_id,
        "PUT",
        "/channels/#{channel_id}/pins/#{message_id}",
        HTTP::Headers.new,
        nil
      )
    end

    def delete_pinned_channel_message(channel_id : UInt64, message_id : UInt64)
      response = request(
        :channels_cid_pins_mid,
        channel_id,
        "DELETE",
        "/channels/#{channel_id}/pins/#{message_id}",
        HTTP::Headers.new,
        nil
      )
    end

    def get_guild(guild_id : UInt64)
      response = request(
        :guilds_gid,
        guild_id,
        "GET",
        "/guilds/#{guild_id}",
        HTTP::Headers.new,
        nil
      )

      Guild.from_json(response.body)
    end

    def modify_guild(guild_id : UInt64, name : String?, region : String?,
                     verification_level : UInt8?, afk_channel_id : UInt64?,
                     afk_timeout : Int32?, icon : String?, owner_id : UInt64?,
                     splash : String?)
      json = {
        name:               name,
        region:             region,
        verification_level: verification_level,
        afk_channel_id:     afk_channel_id,
        afk_timeout:        afk_timeout,
        icon:               icon,
        owner_id:           owner_id,
        splash:             splash,
      }.to_json

      response = request(
        :guilds_gid,
        guild_id,
        "PATCH",
        "/guilds/#{guild_id}",
        HTTP::Headers{"Content-Type" => "application/json"},
        json
      )

      Guild.from_json(response.body)
    end

    def delete_guild(guild_id : UInt64)
      response = request(
        :guilds_gid,
        guild_id,
        "DELETE",
        "/guilds/#{guild_id}",
        HTTP::Headers.new,
        nil
      )

      Guild.from_json(response.body)
    end

    def get_guild_channels(guild_id : UInt64)
      response = request(
        :guilds_gid_channels,
        guild_id,
        "GET",
        "/guilds/#{channel_id}/channels",
        HTTP::Headers.new,
        nil
      )

      Array(Channel).from_json(response.body)
    end

    def create_guild_channel(guild_id : UInt64, name : String, type : UInt8,
                             bitrate : UInt32?, user_limit : UInt32?)
      json = {
        name:       name,
        type:       type,
        bitrate:    bitrate,
        user_limit: user_limit,
      }.to_json

      response = request(
        :guilds_gid_channels,
        guild_id,
        "POST",
        "/guilds/#{guild_id}/channels",
        HTTP::Headers{"Content-Type" => "application/json"},
        json
      )

      Channel.from_json(response.body)
    end

    def modify_guild_channel(guild_id : UInt64, channel_id : UInt64,
                             position : UInt64)
      json = {
        id:       channel_id,
        position: position,
      }.to_json

      response = request(
        :guilds_gid_channels,
        guild_id,
        "PATCH",
        "/guilds/#{guild_id}/channels",
        HTTP::Headers{"Content-Type" => "application/json"},
        json
      )

      Channel.from_json(response.body)
    end

    def get_guild_member(guild_id : UInt64, user_id : UInt64)
      response = request(
        :guilds_gid_members_uid,
        guild_id,
        "GET",
        "/guilds/#{guild_id}/members/#{user_id}",
        HTTP::Headers.new,
        nil
      )

      GuildMember.from_json(response.body)
    end

    def list_guild_members(guild_id : UInt64, limit : UInt8 = 1, after : UInt64 = 0)
      path = "/guilds/#{guild_id}/members?limit=#{limit}&after=#{after}"

      response = request(
        :guilds_gid_members,
        guild_id,
        "GET",
        path,
        HTTP::Headers.new,
        nil
      )

      Array(GuildMember).from_json(response.body)
    end

    def modify_guild_member(guild_id : UInt64, user_id : UInt64, nick : String?,
                            roles : Array(UInt64)?, mute : Bool?, deaf : Bool?,
                            channel_id : UInt64?)
      json = {
        nick:       nick,
        roles:      roles,
        mute:       mute,
        deaf:       deaf,
        channel_id: channel_id,
      }.to_json

      response = request(
        :guilds_gid_members_uid,
        guild_id,
        "PATCH",
        "/guilds/#{guild_id}/members/#{user_id}",
        HTTP::Headers{"Content-Type" => "application/json"},
        json
      )
    end

    def remove_guild_member(guild_id : UInt64, user_id : UInt64)
      response = request(
        :guilds_gid_members_uid,
        guild_id,
        "DELETE",
        "/guilds/#{guild_id}/members/#{user_id}",
        HTTP::Headers.new,
        nil
      )
    end

    def get_guild_bans(guild_id : UInt64)
      response = request(
        :guilds_gid_bans,
        guild_id,
        "GET",
        "/guilds/#{guild_id}/bans",
        HTTP::Headers.new,
        nil
      )

      Array(User).from_json(response.body)
    end

    def create_guild_ban(guild_id : UInt64, user_id : UInt64)
      response = request(
        :guilds_gid_bans_uid,
        guild_id,
        "PUT",
        "/guilds/#{guild_id}/bans/#{user_id}",
        HTTP::Headers.new,
        nil
      )
    end

    def remove_guild_ban(guild_id : UInt64, user_id : UInt64)
      response = request(
        :guilds_gid_bans_uid,
        guild_id,
        "DELETE",
        "/guilds/#{guild_id}/bans/#{user_id}",
        HTTP::Headers.new,
        nil
      )
    end

    def get_guild_roles(guild_id : UInt64)
      response = request(
        :guilds_gid_roles,
        guild_id,
        "GET",
        "/guilds/#{guild_id}/roles",
        HTTP::Headers.new,
        nil
      )

      Array(Role).from_json(response.body)
    end

    def create_guild_role(guild_id : UInt64)
      response = request(
        :get_guild_roles,
        guild_id,
        "POST",
        "/guilds/#{guild_id}/roles",
        HTTP::Headers.new,
        nil
      )

      Role.from_json(response.body)
    end

    def modify_guild_role(guild_id : UInt64, role_id : UInt64, name : String?,
                          permissions : UInt64?, colour : UInt32?,
                          position : Int32?, hoist : Bool?)
      json = {
        name:        name,
        permissions: permissions,
        color:       colour,
        position:    position,
        hoist:       hoist,
      }.to_json

      response = request(
        :guilds_gid_roles_rid,
        guild_id,
        "PATCH",
        "/guilds/#{guild_id}/roles/#{role_id}",
        HTTP::Headers{"Content-Type" => "application/json"},
        json
      )

      Role.from_json(response.body)
    end

    def delete_guild_role(guild_id : UInt64, role_id : UInt64)
      response = request(
        :guilds_gid_roles_rid,
        guild_id,
        "DELETE",
        "/guilds/#{guild_id}/roles/#{role_id}",
        HTTP::Headers.new,
        nil
      )

      Role.from_json(response.body)
    end

    def get_guild_prune_count(guild_id : UInt64, days : UInt32)
      response = request(
        :guilds_gid_prune,
        guild_id,
        "GET",
        "/guilds/#{guild_id}/prune?days=#{days}",
        HTTP::Headers.new,
        nil
      )

      PruneCountResponse.new(response.body)
    end

    def begin_guild_prune(guild_id : UInt64, days : UInt32)
      response = request(
        :guilds_gid_prune,
        guild_id,
        "POST",
        "/guilds/#{guild_id}/prune?days=#{days}",
        HTTP::Headers.new,
        nil
      )

      PruneCountResponse.new(response.body)
    end

    def get_guild_voice_regions(guild_id : UInt64)
      response = request(
        :guilds_gid_regions,
        guild_id,
        "GET",
        "/guilds/#{guild_id}/regions",
        HTTP::Headers.new,
        nil
      )

      Array(VoiceRegion).from_json(response.body)
    end

    def get_guild_integrations(guild_id : UInt64)
      response = request(
        :guilds_gid_integrations,
        guild_id,
        "GET",
        "/guilds/#{guild_id}/integrations",
        HTTP::Headers.new,
        nil
      )

      Array(Integration).from_json(response.body)
    end

    def create_guild_integration(guild_id : UInt64, type : String, id : UInt64)
      json = {
        type: type,
        id:   id,
      }.to_json

      response = request(
        :guilds_gid_integrations,
        guild_id,
        "POST",
        "/guilds/#{guild_id}/integrations",
        HTTP::Headers{"Content-Type" => "application/json"},
        json
      )
    end

    def modify_guild_integration(guild_id : UInt64, integration_id : UInt64,
                                 expire_behaviour : UInt8,
                                 expire_grace_period : Int32,
                                 enable_emoticons : Bool)
      json = {
        expire_behavior:     expire_behaviour,
        expire_grace_period: expire_grace_period,
        enable_emoticons:    enable_emoticons,
      }.to_json

      response = request(
        :guilds_gid_integrations_iid,
        guild_id,
        "PATCH",
        "/guilds/#{guild_id}/integrations/#{integration_id}",
        HTTP::Headers{"Content-Type" => "application/json"},
        json
      )
    end

    def delete_guild_integration(guild_id : UInt64, integration_id : UInt64)
      response = request(
        :guilds_gid_integrations_iid,
        guild_id,
        "DELETE",
        "/guilds/#{guild_id}/integrations/#{integration_id}",
        HTTP::Headers.new,
        nil
      )
    end

    def sync_guild_integration(guild_id : UInt64, integration_id : UInt64)
      response = request(
        :guilds_gid_integrations_iid_sync,
        guild_id,
        "POST",
        "/guilds/#{guild_id}/integrations/#{integration_id}/sync",
        HTTP::Headers.new,
        nil
      )
    end

    def get_guild_embed(guild_id : UInt64)
      response = request(
        :guilds_gid_embed,
        guild_id,
        "GET",
        "/guilds/#{guild_id}/embed",
        HTTP::Headers.new,
        nil
      )

      GuildEmbed.from_json(response.body)
    end

    def modify_guild_embed(guild_id : UInt64, enabled : Bool,
                           channel_id : UInt64)
      json = {
        enabled:    enabled,
        channel_id: channel_id,
      }.to_json

      response = request(
        :guilds_gid_embed,
        guild_id,
        "PATCH",
        "/guilds/#{guild_id}/embed",
        HTTP::Headers{"Content-Type" => "application/json"},
        json
      )

      GuildEmbed.from_json(response.body)
    end

    def get_user(user_id : UInt64)
      response = request(
        :users_uid,
        nil,
        "GET",
        "/users/#{user_id}",
        HTTP::Headers.new,
        nil
      )

      User.from_json(response.body)
    end

    def query_users(query : String, limit : Int32 = 25)
      response = request(
        :users,
        nil,
        "GET",
        "/users?q=#{query}&limit=#{limit}",
        HTTP::Headers.new,
        nil
      )

      Array(User).from_json(response.body)
    end

    def get_current_user
      response = request(
        :users_me,
        nil,
        "GET",
        "/users/@me",
        HTTP::Headers.new,
        nil
      )

      User.from_json(response.body)
    end

    def modify_current_user(username : String, avatar : String)
      json = {
        username: username,
        avatar:   avatar,
      }.to_json

      response = request(
        :users_me,
        nil,
        "PATCH",
        "/users/@me",
        HTTP::Headers{"Content-Type" => "application/json"},
        json
      )

      User.from_json(response.body)
    end

    def get_current_user_guilds
      response = request(
        :users_me_guilds,
        nil,
        "GET",
        "/users/@me/guilds",
        HTTP::Headers.new,
        nil
      )

      Array(UserGuild).from_json(response.body)
    end

    def leave_guild(guild_id : UInt64)
      response = request(
        :users_me_guilds_gid,
        nil,
        "DELETE",
        "/users/@me/guilds/#{guild_id}",
        HTTP::Headers.new,
        nil
      )
    end

    def get_user_dms
      response = request(
        :users_me_channels,
        nil,
        "GET",
        "/users/@me/channels",
        HTTP::Headers.new,
        nil
      )

      Array(PrivateChannel).from_json(response.body)
    end

    def create_dm(recipient_id : UInt64)
      response = request(
        :users_me_channels,
        nil,
        "POST",
        "/users/@me/channels",
        HTTP::Headers{"Content-Type" => "application/json"},
        {recipient_id: recipient_id}.to_json
      )

      PrivateChannel.from_json(response.body)
    end

    def get_users_connections
      response = request(
        :users_me_connections,
        nil,
        "GET",
        "/users/@me/connections",
        HTTP::Headers.new,
        nil
      )

      Array(Connection).from_json(response.body)
    end

    def get_invite(code : String)
      response = request(
        :invites_code,
        nil,
        "GET",
        "/invites/#{code}",
        HTTP::Headers.new,
        nil
      )

      Invite.from_json(response.body)
    end

    def delete_invite(code : String)
      response = request(
        :invites_code,
        nil,
        "DELETE",
        "/invites/#{code}",
        HTTP::Headers.new,
        nil
      )

      Invite.from_json(response.body)
    end

    def accept_invite(code : String)
      response = request(
        :invites_code,
        nil,
        "POST",
        "/invites/#{code}",
        HTTP::Headers.new,
        nil
      )

      Invite.from_json(response.body)
    end

    def list_voice_regions
      response = request(
        :voice_regions,
        nil,
        "GET",
        "/voice/regions",
        HTTP::Headers.new,
        nil
      )

      Array(VoiceRegion).from_json(response.body)
    end
  end
end
