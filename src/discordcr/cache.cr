require "./mappings/*"

module Discord
  class Cache
    def initialize(@client : Client)
      @users = Hash(UInt64, User).new
      @channels = Hash(UInt64, Channel).new
      @guilds = Hash(UInt64, Guild).new
      @members = Hash(UInt64, Hash(UInt64, GuildMember)).new
    end

    def resolve_user(id : UInt64) : User
      @users.fetch(id) { @users[id] = @client.get_user(id) }
    end

    def resolve_channel(id : UInt64) : Channel
      @channels.fetch(id) { @channels[id] = @client.get_channel(id) }
    end

    def resolve_guild(id : UInt64) : Guild
      @guilds.fetch(id) { @guilds[id] = @client.get_guild(id) }
    end

    def resolve_member(guild_id : UInt64, user_id : UInt64) : GuildMember
      local_members = @members[guild_id] ||= Hash(UInt64, GuildMember).new
      local_members.fetch(user_id) { local_members[user_id] = @client.get_guild_member(guild_id, user_id) }
    end

    def cache(user : User)
      @users[user.id] = user
    end

    def cache(channel : Channel)
      @channels[channel.id] = channel
    end

    def cache(guild : Guild)
      @guilds[guild.id] = guild
    end

    def cache(member : GuildMember, guild_id : UInt64)
      local_members = @members[guild_id] ||= Hash(UInt64, GuildMember).new
      local_members[member.user.id] = member
    end
  end
end
