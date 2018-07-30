# This module contains methods for building URLs to resources on Discord's CDN
# for things like guild icons and avatars.
#
# NOTE: All `size` arguments for CDN methods must be a power of 2 between 16
# and 2048. If an invalid size is given, `ArgumentError` will be raised.
#
# [API Documentation for image formatting](https://discordapp.com/developers/docs/reference#image-formatting)
module Discord::CDN
  extend self

  # Base CDN URL
  BASE_URL = "https://cdn.discordapp.com"

  # Available image formats for custom emoji
  enum CustomEmojiFormat
    PNG
    GIF

    def to_s
      case self
      when PNG
        "png"
      when GIF
        "gif"
      end
    end

    def to_s(io : IO)
      io << to_s
    end
  end

  # Available image formats for guild icons
  enum GuildIconFormat
    PNG
    JPEG
    WebP

    def to_s
      case self
      when PNG
        "png"
      when JPEG
        "jpeg"
      when WebP
        "webp"
      end
    end

    def to_s(io : IO)
      io << to_s
    end
  end

  # Available image formats for guild splashes
  enum GuildSplashFormat
    PNG
    JPEG
    WebP

    def to_s
      case self
      when PNG
        "png"
      when JPEG
        "jpeg"
      when WebP
        "webp"
      end
    end

    def to_s(io : IO)
      io << to_s
    end
  end

  # Available image formats for user avatars
  enum UserAvatarFormat
    PNG
    JPEG
    WebP
    GIF

    def to_s
      case self
      when PNG
        "png"
      when JPEG
        "jpeg"
      when WebP
        "webp"
      when GIF
        "gif"
      end
    end

    def to_s(io : IO)
      io << to_s
    end
  end

  # Available image formats for application icons
  enum ApplicationIconFormat
    PNG
    JPEG
    WebP
    GIF

    def to_s
      case self
      when PNG
        "png"
      when JPEG
        "jpeg"
      when WebP
        "webp"
      when GIF
        "gif"
      end
    end

    def to_s(io : IO)
      io << to_s
    end
  end

  private def check_size(value : Int32)
    in_range = (16..2048).includes?(value)
    power_of_two = (value > 0) && ((value & (value - 1)) == 0)
    unless in_range && power_of_two
      raise ArgumentError.new("Size #{value} is not between 16 and 2048 and a power of 2")
    end
  end

  # Produces a CDN URL for a custom emoji in the given `format` and `size`
  def custom_emoji(id : UInt64 | Snowflake,
                   format : CustomEmojiFormat = CustomEmojiFormat::PNG,
                   size : Int32 = 128)
    check_size(size)
    "#{BASE_URL}/emojis/#{id}.#{format}?size=#{size}"
  end

  # Produces a CDN URL for a guild icon in the given `format` and `size`
  def guild_icon(id : UInt64 | Snowflake, icon : String,
                 format : GuildIconFormat = GuildIconFormat::WebP,
                 size : Int32 = 128)
    check_size(size)
    "#{BASE_URL}/icons/#{id}/#{icon}.#{format}?size=#{size}"
  end

  # Produces a CDN URL for a guild splash in the given `format` and `size`
  def guild_splash(id : UInt64 | Snowflake, splash : String,
                   format : GuildSplashFormat = GuildSplashFormat::WebP,
                   size : Int32 = 128)
    check_size(size)
    "#{BASE_URL}/splashes/#{id}/#{splash}.#{format}?size=#{size}"
  end

  # Produces a CDN URL for a default user avatar, calculated from the given
  # discriminator value.
  def default_user_avatar(user_discriminator : String)
    index = user_discriminator.to_i % 5
    "#{BASE_URL}/embed/avatars/#{index}.png"
  end

  # Produces a CDN URL for a user avatar in the given `size`. Given the `avatar`
  # string, this will return a WebP or GIF based on the animated avatar hint.
  def user_avatar(id : UInt64 | Snowflake, avatar : String, size : Int32 = 128)
    if avatar.starts_with?("a_")
      user_avatar(id, avatar, UserAvatarFormat::GIF, size)
    else
      user_avatar(id, avatar, UserAvatarFormat::WebP, size)
    end
  end

  # Produces a CDN URL for a user avatar in the given `format` and `size`
  def user_avatar(id : UInt64 | Snowflake, avatar : String,
                  format : UserAvatarFormat, size : Int32 = 128)
    check_size(size)
    "#{BASE_URL}/avatars/#{id}/#{avatar}.#{format}?size=#{size}"
  end

  # Produces a CDN URL for an application icon in the given `format` and `size`
  def application_icon(id : UInt64 | Snowflake, icon : String,
                       format : ApplicationIconFormat = ApplicationIconFormat::WebP,
                       size : Int32 = 128)
    check_size(size)
    "#{BASE_URL}/app-icons/#{id}/#{icon}.#{format}?size=#{size}"
  end
end
