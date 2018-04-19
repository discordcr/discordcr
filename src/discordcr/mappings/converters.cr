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
