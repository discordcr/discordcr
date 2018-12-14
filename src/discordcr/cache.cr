require "./mappings/*"

module Discord
  # A cache is a utility class that stores various kinds of Discord objects,
  # like `User`s, `Role`s etc. Its purpose is to reduce both the load on
  # Discord's servers and reduce the latency caused by having to do an API call.
  # It is recommended to use caching for bots that interact heavily with
  # Discord-provided data, like for example administration bots, as opposed to
  # bots that only interact by sending and receiving messages. For that latter
  # kind, caching is usually even counter-productive as it only unnecessarily
  # increases memory usage.
  #
  # Caching can either be used standalone, in a purely REST-based way:
  # ```
  # client = Discord::Client.new(token: "Bot token", client_id: 123_u64)
  # cache = Discord::Cache.new(client)
  #
  # puts cache.resolve_user(66237334693085184) # will perform API call
  # puts cache.resolve_user(66237334693085184) # will not perform an API call, as the data is now cached
  # ```
  #
  # It can also be integrated more deeply into a `Client` (specifically one that
  # uses a gateway connection) to reduce cache misses even more by automatically
  # caching data received over the gateway:
  # ```
  # client = Discord::Client.new(token: "Bot token", client_id: 123_u64)
  # cache = Discord::Cache.new(client)
  # client.cache = cache # Integrate the cache into the client
  # ```
  #
  # Note that if a cache is *not* used this way, its data will slowly go out of
  # sync with Discord, and unless it is used in an environment with few changes
  # likely to occur, a client without a gateway connection should probably
  # refrain from caching at all.
  class Cache
    # A map of cached users. These aren't necessarily all the users in servers
    # the bot has access to, but rather all the users that have been seen by
    # the bot in the past (and haven't been deleted by means of `delete_user`).
    getter users

    # A map of cached channels, i. e. all channels on all servers the bot is on,
    # as well as all DM channels.
    getter channels

    # A map of guilds (servers) the bot is on. Doesn't ignore guilds temporarily
    # deleted due to an outage; so if an outage is going on right now the
    # affected guilds would be missing here too.
    getter guilds

    # A double map of members on servers, represented as {guild ID => {user ID
    # => member}}. Will only contain previously and currently online members as
    # well as all members that have been chunked (see
    # `Client#request_guild_members`).
    getter members

    # A map of all roles on servers the bot is on. Does not discriminate by
    # guild, as role IDs are unique even across guilds.
    getter roles

    # Mapping of users to the respective DM channels the bot has open with them,
    # represented as {user ID => channel ID}.
    getter dm_channels

    # Mapping of guilds to the roles on them, represented as {guild ID =>
    # [role IDs]}.
    getter guild_roles

    # Mapping of guilds to the channels on them, represented as {guild ID =>
    # [channel IDs]}.
    getter guild_channels

    # Creates a new cache with a *client* that requests (in case of cache
    # misses) should be done on.
    def initialize(@client : Client)
      @users = Hash(UInt64, User).new
      @channels = Hash(UInt64, Channel).new
      @guilds = Hash(UInt64, Guild).new
      @members = Hash(UInt64, Hash(UInt64, GuildMember)).new
      @roles = Hash(UInt64, Role).new

      @dm_channels = Hash(UInt64, UInt64).new

      @guild_roles = Hash(UInt64, Array(UInt64)).new
      @guild_channels = Hash(UInt64, Array(UInt64)).new
    end

    # Resolves a user by its *ID*. If the requested object is not cached, it
    # will do an API call.
    def resolve_user(id : UInt64 | Snowflake) : User
      id = id.to_u64
      @users.fetch(id) { @users[id] = @client.get_user(id) }
    end

    # Resolves a channel by its *ID*. If the requested object is not cached, it
    # will do an API call.
    def resolve_channel(id : UInt64 | Snowflake) : Channel
      id = id.to_u64
      @channels.fetch(id) { @channels[id] = @client.get_channel(id) }
    end

    # Resolves a guild by its *ID*. If the requested object is not cached, it
    # will do an API call.
    def resolve_guild(id : UInt64 | Snowflake) : Guild
      id = id.to_u64
      @guilds.fetch(id) { @guilds[id] = @client.get_guild(id) }
    end

    # Resolves a member by the *guild_id* of the guild the member is on, and the
    # *user_id* of the member itself. An API request will be performed if the
    # object is not cached.
    def resolve_member(guild_id : UInt64 | Snowflake, user_id : UInt64 | Snowflake) : GuildMember
      guild_id = guild_id.to_u64
      user_id = user_id.to_u64
      local_members = @members[guild_id] ||= Hash(UInt64, GuildMember).new
      local_members.fetch(user_id) { local_members[user_id] = @client.get_guild_member(guild_id, user_id) }
    end

    # Resolves a role by its *ID*. No API request will be performed if the role
    # is not cached, because there is no endpoint for individual roles; however
    # all roles should be cached at all times so it won't be a problem.
    def resolve_role(id : UInt64 | Snowflake) : Role
      @roles[id.to_u64] # There is no endpoint for getting an individual role, so we will have to ignore that case for now.
    end

    # Resolves the ID of a DM channel with a particular user by the recipient's
    # *recipient_id*. If there is no such channel cached, one will be created.
    def resolve_dm_channel(recipient_id : UInt64 | Snowflake) : UInt64
      recipient_id = recipient_id.to_u64
      @dm_channels.fetch(recipient_id) do
        channel = @client.create_dm(recipient_id)
        cache(Channel.new(channel))
        @dm_channels[recipient_id] = channel.id.to_u64
      end
    end

    # Resolves the current user's profile. Requires no parameters since the
    # endpoint has none either. If there is a gateway connection this should
    # always be cached.
    def resolve_current_user : User
      @current_user ||= @client.get_current_user
    end

    # Deletes a user from the cache given its *ID*.
    def delete_user(id : UInt64 | Snowflake)
      @users.delete(id.to_u64)
    end

    # Deletes a channel from the cache given its *ID*.
    def delete_channel(id : UInt64 | Snowflake)
      @channels.delete(id.to_u64)
    end

    # Deletes a guild from the cache given its *ID*.
    def delete_guild(id : UInt64 | Snowflake)
      @guilds.delete(id.to_u64)
    end

    # Deletes a member from the cache given its *user_id* and the *guild_id* it
    # is on.
    def delete_member(guild_id : UInt64 | Snowflake, user_id : UInt64 | Snowflake)
      guild_id = guild_id.to_u64
      user_id = user_id.to_u64
      @members[guild_id]?.try &.delete(user_id)
    end

    # Deletes a role from the cache given its *ID*.
    def delete_role(id : UInt64 | Snowflake)
      @roles.delete(id.to_u64)
    end

    # Deletes a DM channel with a particular user given the *recipient_id*.
    def delete_dm_channel(recipient_id : UInt64 | Snowflake)
      @dm_channels.delete(recipient_id.to_u64)
    end

    # Deletes the current user from the cache, if that will ever be necessary.
    def delete_current_user
      @current_user = nil
    end

    # Adds a specific *user* to the cache.
    def cache(user : User)
      @users[user.id.to_u64] = user
    end

    # Adds a specific *channel* to the cache.
    def cache(channel : Channel)
      @channels[channel.id.to_u64] = channel
    end

    # Adds a specific *guild* to the cache.
    def cache(guild : Guild)
      @guilds[guild.id.to_u64] = guild
    end

    # Adds a specific *member* to the cache, given the *guild_id* it is on.
    def cache(member : GuildMember, guild_id : UInt64 | Snowflake)
      guild_id = guild_id.to_u64
      local_members = @members[guild_id] ||= Hash(UInt64, GuildMember).new
      local_members[member.user.id.to_u64] = member
    end

    # Adds a specific *role* to the cache.
    def cache(role : Role)
      @roles[role.id.to_u64] = role
    end

    # Adds a particular DM channel to the cache, given the *channel_id* and the
    # *recipient_id*.
    def cache_dm_channel(channel_id : UInt64 | Snowflake, recipient_id : UInt64 | Snowflake)
      channel_id = channel_id.to_u64
      recipient_id = recipient_id.to_u64
      @dm_channels[recipient_id] = channel_id
    end

    # Caches the current user.
    def cache_current_user(@current_user : User); end

    # Adds multiple *members* at once to the cache, given the *guild_id* they
    # all share. This method exists to slightly reduce the overhead of
    # processing chunks; outside of that it is likely not of much use.
    def cache_multiple_members(members : Array(GuildMember), guild_id : UInt64 | Snowflake)
      guild_id = guild_id.to_u64
      local_members = @members[guild_id] ||= Hash(UInt64, GuildMember).new
      members.each do |member|
        local_members[member.user.id.to_u64] = member
      end
    end

    # Returns all roles of a guild, identified by its *guild_id*.
    def guild_roles(guild_id : UInt64 | Snowflake) : Array(UInt64)
      @guild_roles[guild_id.to_u64]
    end

    # Marks a role, identified by the *role_id*, as belonging to a particular
    # guild, identified by the *guild_id*.
    def add_guild_role(guild_id : UInt64 | Snowflake, role_id : UInt64 | Snowflake)
      guild_id = guild_id.to_u64
      role_id = role_id.to_u64
      local_roles = @guild_roles[guild_id] ||= [] of UInt64
      local_roles << role_id
    end

    # Marks a role as not belonging to a particular guild anymore.
    def remove_guild_role(guild_id : UInt64 | Snowflake, role_id : UInt64 | Snowflake)
      guild_id = guild_id.to_u64
      role_id = role_id.to_u64
      @guild_roles[guild_id]?.try { |local_roles| local_roles.delete(role_id) }
    end

    # Returns all channels of a guild, identified by its *guild_id*.
    def guild_channels(guild_id : UInt64 | Snowflake) : Array(UInt64)
      @guild_channels[guild_id.to_u64]
    end

    # Marks a channel, identified by the *channel_id*, as belonging to a particular
    # guild, identified by the *guild_id*.
    def add_guild_channel(guild_id : UInt64 | Snowflake, channel_id : UInt64 | Snowflake)
      guild_id = guild_id.to_u64
      channel_id = channel_id.to_u64
      local_channels = @guild_channels[guild_id] ||= [] of UInt64
      local_channels << channel_id
    end

    # Marks a channel as not belonging to a particular guild anymore.
    def remove_guild_channel(guild_id : UInt64 | Snowflake, channel_id : UInt64 | Snowflake)
      guild_id = guild_id.to_u64
      channel_id = channel_id.to_u64
      @guild_channels[guild_id]?.try { |local_channels| local_channels.delete(channel_id) }
    end
  end
end
