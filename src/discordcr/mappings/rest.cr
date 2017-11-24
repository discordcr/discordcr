require "./converters"

module Discord
  module REST
    # A response to the Get Gateway REST API call.
    struct GatewayResponse
      JSON.mapping(
        url: String
      )
    end

    # A response to the Get Guild Prune Count REST API call.
    struct PruneCountResponse
      JSON.mapping(
        pruned: UInt32
      )
    end

    # A response to the Get Guild Vanity URL REST API call.
    struct GuildVanityURLResponse
      JSON.mapping(
        code: String
      )
    end

    # A request payload to rearrange channels in a `Guild` by a REST API call.
    struct ModifyChannelPositionPayload
      JSON.mapping(
        id: {type: UInt64, converter: SnowflakeConverter},
        position: Int32,
        parent_id: {type: UInt64?, converter: MaybeSnowflakeConverter},
        lock_permissions: Bool?
      )

      def initialize(@id, @position, @parent_id = nil, @lock_permissions = nil)
      end
    end
  end
end
