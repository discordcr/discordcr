require "json"
require "time/format"

module Discord
  # :nodoc:
  module TimestampConverter
    def self.from_json(parser : JSON::PullParser)
      time_str = parser.read_string

      begin
        Time::Format.new("%FT%T.%6N%:z").parse(time_str)
      rescue Time::Format::Error
        Time::Format.new("%FT%T%:z").parse(time_str)
      end
    end

    def self.to_json(value : Time, builder : JSON::Builder)
      Time::Format.new("%FT%T.%6N%:z").to_json(value, builder)
    end
  end

  # :nodoc:
  module SnowflakeConverter
    def self.from_json(parser : JSON::PullParser) : UInt64
      parser.read_string.to_u64
    end

    def self.to_json(value : UInt64, builder : JSON::Builder)
      builder.scalar(value.to_s)
    end
  end

  # :nodoc:
  module MaybeSnowflakeConverter
    def self.from_json(parser : JSON::PullParser) : UInt64?
      str = parser.read_string_or_null

      if str
        str.to_u64
      else
        nil
      end
    end

    def self.to_json(value : UInt64?, builder : JSON::Builder)
      if value
        builder.scalar(value.to_s)
      else
        builder.null
      end
    end
  end

  # :nodoc:
  module SnowflakeArrayConverter
    def self.from_json(parser : JSON::PullParser) : Array(UInt64)
      Array(String).new(parser).map &.to_u64
    end

    def self.to_json(value : Array(UInt64), builder : JSON::Builder)
      value.map(&.to_s).to_json(builder)
    end
  end

  # :nodoc:
  module MessageTypeConverter
    def self.from_json(parser : JSON::PullParser)
      if value = parser.read?(UInt8)
        MessageType.new(value)
      else
        raise "Unexpected message type value: #{parser.read_raw}"
      end
    end

    def self.to_json(value : MessageType, builder : JSON::Builder)
      value.to_json(builder)
    end
  end

  # :nodoc:
  module ChannelTypeConverter
    def self.from_json(parser : JSON::PullParser)
      if value = parser.read?(UInt8)
        ChannelType.new(value)
      else
        raise "Unexpected channel type value: #{parser.read_raw}"
      end
    end
  end
end
