require "./converters"

module Discord
  module REST
    # A response to the Get Gateway REST API call.
    struct GatewayResponse
      JSON.mapping(
        url: String
      )
    end

    # A response to the Get Gateway Bot REST API call.
    struct GatewayBotResponse
      JSON.mapping(
        url: String,
        shards: Int32,
        session_start_limit: SessionStartLimit
      )
    end

    # Session start limit details included in the Get Gateway Bot REST API call.
    struct SessionStartLimit
      JSON.mapping(
        total: Int32,
        remaining: Int32,
        reset_after: {type: Time::Span, converter: TimeSpanMillisecondsConverter}
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
      @id : Snowflake

      def initialize(id : UInt64 | Snowflake, @position : Int32,
                     @parent_id : UInt64 | Snowflake | ChannelParent = ChannelParent::Unchanged,
                     @lock_permissions : Bool? = nil)
        id = Snowflake.new(id) unless id.is_a?(Snowflake)
        @id = id
      end

      def to_json(builder : JSON::Builder)
        builder.object do
          builder.field("id") { @id.to_json(builder) }

          builder.field("position", @position)

          case parent = @parent_id
          when UInt64, Snowflake
            parent.to_json(builder)
          when ChannelParent::None
            builder.field("parent_id", nil)
          when ChannelParent::Unchanged
            # no field
          end

          builder.field("lock_permissions", @lock_permissions) unless @lock_permissions.nil?
        end
      end
    end
  end
end
