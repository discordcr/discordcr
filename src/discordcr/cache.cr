require "./mappings/*"

module Discord
  class Cache
    def initialize(@client : Client)
      @users = Hash(UInt64, User).new
    end

    def resolve_user(id : UInt64) : User
      user = @users[id]?
      return user if user

      user = @client.get_user(id)
      @users[id] = user
      user
    end
  end
end
