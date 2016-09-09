require "./mappings/*"

module Discord
  class Cache
    def initialize(@client : Client)
      @users = Hash(UInt64, User).new
      @channels = Hash(UInt64, Channel).new
      @guilds = Hash(UInt64, Guild).new
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

    def cache(user : User)
      @users[user.id] = user
    end

    def cache(channel : Channel)
      @channels[channel.id] = channel
    end

    def cache(guild : Guild)
      @guilds[guild.id] = guild
    end
  end
end
