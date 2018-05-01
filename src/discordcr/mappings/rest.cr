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
      def initialize(@id : UInt64, @position : Int32,
                     @parent_id : UInt64 | ChannelParent = ChannelParent::Unchanged,
                     @lock_permissions : Bool? = nil)
      end

      def to_json(builder : JSON::Builder)
        builder.object do
          builder.field("id") do
            SnowflakeConverter.to_json(@id, builder)
          end

          builder.field("position", @position)

          case parent = @parent_id
          when UInt64
            SnowflakeConverter.to_json(parent, builder)
          when ChannelParent::None
            builder.field("parent_id", nil)
          when ChannelParent::Unchanged
            # no field
          end

          builder.field("lock_permissions", @lock_permissions) unless @lock_permissions.nil?
        end
      end
    end

    # A request to the Modify Webhook REST API call.
    class ModifyWebhookPayload
      JSON.mapping(
        name: String?,
        avatar: String?,
        channel_id: UInt64?
      )

      def initialize(@name, @avatar, @channel_id)
      end
    end

    # A request to the Execute Webhook REST API call.
    class ExecuteWebhookPayload
      JSON.mapping(
        content: String?,
        file: String?,
        embeds: Array(Embed)?,
        tts: Bool?,
        avatar_url: String?,
        username: String?
      )

      def initialize(@content, @file, @embeds, @tts, @avatar_url, @username)
      end
    end

    # A response to the Modify Webhook REST API call.
    class ModifyWebhookPayload
      JSON.mapping(name: String?, avatar: String?, channel_id: UInt64?)

      def initialize(@name, @avatar, @channel_id)
      end
    end
  end
end
