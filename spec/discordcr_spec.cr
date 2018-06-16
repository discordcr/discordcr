require "yaml"
require "./spec_helper"

struct StructWithSnowflake
  JSON.mapping(
    data: {type: UInt64, converter: Discord::SnowflakeConverter}
  )
end

struct StructWithMaybeSnowflake
  JSON.mapping(
    data: {type: UInt64?, converter: Discord::MaybeSnowflakeConverter}
  )
end

struct StructWithSnowflakeArray
  JSON.mapping(
    data: {type: Array(UInt64), converter: Discord::SnowflakeArrayConverter}
  )
end

struct StructWithTime
  JSON.mapping(
    data: {type: Time, converter: Discord::TimestampConverter}
  )
end

struct StructWithMessageType
  JSON.mapping(
    data: {type: Discord::MessageType, converter: Discord::MessageTypeConverter}
  )
end

struct StructWithChannelType
  JSON.mapping(
    data: {type: Discord::ChannelType, converter: Discord::ChannelTypeConverter}
  )
end

describe Discord do
  describe "VERSION" do
    it "matches shards.yml" do
      version = YAML.parse(File.read(File.join(__DIR__, "..", "shard.yml")))["version"].as_s
      version.should eq(Discord::VERSION)
    end
  end

  describe Discord::TimestampConverter do
    it "parses a time with floating point accuracy" do
      json = %({"data":"2017-11-16T13:09:18.291000+00:00"})

      obj = StructWithTime.from_json(json)
      obj.data.should be_a Time
    end

    it "parses a time without floating point accuracy" do
      json = %({"data":"2017-11-15T02:23:35+00:00"})

      obj = StructWithTime.from_json(json)
      obj.data.should be_a Time
    end

    it "serializes" do
      json = %({"data":"2017-11-16T13:09:18.291000+00:00"})
      obj = StructWithTime.from_json(json)
      obj.to_json.should eq json
    end
  end

  describe Discord::SnowflakeConverter do
    it "converts a string to u64" do
      json = %({"data":"10000000000"})

      obj = StructWithSnowflake.from_json(json)
      obj.data.should eq 10000000000
      obj.data.should be_a UInt64
    end
  end

  describe Discord::MaybeSnowflakeConverter do
    it "converts a string to u64" do
      json = %({"data":"10000000000"})

      obj = StructWithMaybeSnowflake.from_json(json)
      obj.data.should eq 10000000000
      obj.data.should be_a UInt64
    end

    it "converts null to nil" do
      json = %({"data":null})

      obj = StructWithMaybeSnowflake.from_json(json)
      obj.data.should eq nil
    end
  end

  describe Discord::SnowflakeArrayConverter do
    it "converts an array of strings to u64s" do
      json = %({"data":["1", "2", "10000000000"]})

      obj = StructWithSnowflakeArray.from_json(json)
      obj.data.should be_a Array(UInt64)
      obj.data[0].should eq 1
      obj.data[1].should eq 2
      obj.data[2].should eq 10000000000
    end
  end

  describe Discord::REST::ModifyChannelPositionPayload do
    describe "#to_json" do
      context "parent_id is ChannelParent::Unchanged" do
        it "doesn't emit parent_id" do
          payload = {Discord::REST::ModifyChannelPositionPayload.new(0_u64, 0, Discord::REST::ChannelParent::Unchanged, true)}
          payload.to_json.should eq %([{"id":"0","position":0,"lock_permissions":true}])
        end
      end

      context "parent_id is ChannelParent::None" do
        it "emits null for parent_id" do
          payload = {Discord::REST::ModifyChannelPositionPayload.new(0_u64, 0, Discord::REST::ChannelParent::None, true)}
          payload.to_json.should eq %([{"id":"0","position":0,"parent_id":null,"lock_permissions":true}])
        end
      end
    end
  end

  describe Discord::MessageTypeConverter do
    it "converts an integer into a MessageType" do
      json = %({"data": 0})

      obj = StructWithMessageType.from_json(json)
      obj.data.should eq Discord::MessageType::Default
    end

    context "with an invalid json value" do
      it "raises" do
        json = %({"data":"foo"})

        expect_raises(Exception, %(Unexpected message type value: "foo")) do
          StructWithMessageType.from_json(json)
        end
      end
    end
  end

  describe Discord::WebSocket::Packet do
    it "inspects" do
      packet = Discord::WebSocket::Packet.new(0_i64, 1_i64, IO::Memory.new("foo"), "test")
      packet.inspect.should eq %(Discord::WebSocket::Packet(@opcode=0_i64 @sequence=1_i64 @data="foo" @event_type="test"))
    end
  end

  describe Discord::ChannelTypeConverter do
    it "converts an integer into a ChannelType" do
      json = %({"data": 0})

      obj = StructWithChannelType.from_json(json)
      obj.data.should eq Discord::ChannelType::GuildText
    end

    context "with an invalid json value" do
      it "raises" do
        json = %({"data":"foo"})

        expect_raises(Exception, %(Unexpected channel type value: "foo")) do
          StructWithChannelType.from_json(json)
        end
      end
    end
  end
end
