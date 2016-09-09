require "./mappings/*"

module Discord
  class Cache
    def initialize(@client : Client)
      @users = Hash(UInt64, User).new
    end

    def resolve_user(id : UInt64) : User
      @users.fetch(id) { @users[id] = @client.get_user(id) }
    end

    def cache(user : User)
      @users[user.id] = user
    end
  end
end
