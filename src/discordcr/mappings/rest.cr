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
