module Discord
  @[Flags]
  enum Permissions : UInt64
    CreateInstantInvite = 1
    KickMembers         = 1 << 1
    BanMembers          = 1 << 2
    Administrator       = 1 << 3
    ManageChannels      = 1 << 4
    ManageGuild         = 1 << 5
    AddReactions        = 1 << 6
    ReadMessages        = 1 << 10
    SendMessages        = 1 << 11
    SendTTSMessages     = 1 << 12
    ManageMessages      = 1 << 13
    EmbedLinks          = 1 << 14
    AttachFiles         = 1 << 15
    ReadMessageHistory  = 1 << 16
    MentionEveryone     = 1 << 17
    UseExternalEmojis   = 1 << 18
    Connect             = 1 << 20
    Speak               = 1 << 21
    MuteMembers         = 1 << 22
    DeafenMembers       = 1 << 23
    MoveMembers         = 1 << 24
    UseVAD              = 1 << 25
    ChangeNickname      = 1 << 26
    ManageNicknames     = 1 << 27
    ManageRoles         = 1 << 28
    ManageWebhooks      = 1 << 29
    ManageEmojis        = 1 << 30

    def self.new(pull : JSON::PullParser)
      # see https://github.com/crystal-lang/crystal/issues/3448
      # #from_value errors
      Permissions.new(pull.read_int.to_u64)
    end
  end
end
