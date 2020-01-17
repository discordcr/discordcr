require "./converters"
require "./user"

module Discord
  # An OAuth2 application, as registered with Discord, that can hold
  # information about a `Client`'s associated bot user account and owner,
  # among other OAuth2 properties.
  struct OAuth2Application
    JSON.mapping({
      id:                     Snowflake,
      name:                   String,
      icon:                   String?,
      description:            String?,
      rpc_origins:            Array(String)?,
      bot_public:             Bool,
      bot_require_code_grant: Bool,
      owner:                  User,
      summary:                String,
      verify_key:             String,
      team:                   Team?,
      guild_id:               Snowflake?,
      primary_sku_id:         String?,
      slug:                   String?,
      cover_image:            String?,
    })

    # Produces a CDN URL for this application's icon in the given `format` and `size`
    def icon_url(format : CDN::ApplicationIconFormat = CDN::ApplicationIconFormat::WebP,
                 size : Int32 = 128)
      if icon = @icon
        CDN.application_icon(id, icon, format, size)
      end
    end
  end

  struct Team
    JSON.mapping({
      icon:          String?,
      id:            Snowflake,
      members:       Array(TeamMember),
      owner_user_id: Snowflake,
    })
  end

  struct TeamMember
    JSON.mapping({
      membership_state: TeamMembershipState,
      permissions:      Array(String),
      team_id:          Snowflake,
      user:             User,
    })
  end

  enum TeamMembershipState : UInt8
    Invited  = 1
    Accepted = 2

    def self.new(pull : JSON::PullParser)
      TeamMembershipState.new(pull.read_int.to_u8)
    end
  end
end
