require "./converters"

module Discord
  module REST
    # Enum for controlling emission of JSON key/value pairs where
    # JSON `null` is a significant value.
    enum MaybeField
      None
      Unchanged
    end

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
      def initialize(@id : UInt64, @position : Int32,
                     @parent_id : UInt64 | MaybeField = MaybeField::Unchanged,
                     @lock_permissions : Bool? = nil)
      end

      def to_json(builder : JSON::Builder)
        builder.object do
          builder.field("id") do
            SnowflakeConverter.to_json(@id, builder)
          end

          builder.field("position", @position)

          parent = @parent_id

          if parent.is_a?(MaybeField)
            if parent.none?
              builder.field("parent_id", nil)
            end
          else
            builder.field("parent_id") do
              SnowflakeConverter.to_json(parent, builder)
            end
          end

          builder.field("lock_permissions", @lock_permissions) unless @lock_permissions.nil?
        end
      end
    end
  end
end
