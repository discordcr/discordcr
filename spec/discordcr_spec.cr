require "yaml"
require "./spec_helper"

struct StructWithTime
  JSON.mapping(
    data: {type: Time, converter: Discord::TimestampConverter}
  )
end

struct StructWithMaybeTime
  JSON.mapping(
    data: {type: Time?, converter: Discord::MaybeTimestampConverter, emit_null: true}
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

    it "raises on null" do
      json = %({"data":null})
      expect_raises(JSON::ParseException) do
        StructWithTime.from_json(json)
      end
    end
  end

  describe Discord::MaybeTimestampConverter do
    it "parses a time" do
      json = %({"data":"2017-11-16T13:09:18.291000+00:00"})
      StructWithMaybeTime.from_json(json).data.should be_a Time
    end

    it "parses null" do
      json = %({"data":null})
      StructWithMaybeTime.from_json(json).data.should be_nil
    end

    it "serializes a time" do
      json = %({"data":"2017-11-16T13:09:18.291000+00:00"})
      obj = StructWithMaybeTime.from_json(json)
      obj.to_json.should eq json
    end

    it "serializes null" do
      json = %({"data":null})
      obj = StructWithMaybeTime.from_json(json)
      obj.to_json.should eq json
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

  describe Discord::WebSocket::Packet do
    it "inspects" do
      packet = Discord::WebSocket::Packet.new(0_i64, 1_i64, IO::Memory.new("foo"), "test")
      packet.inspect.should eq %(Discord::WebSocket::Packet(@opcode=0_i64 @sequence=1_i64 @data="foo" @event_type="test"))
    end

    it "serializes" do
      json = %({"op":0,"s":1,"d":"foo","t":"test"})
      packet = Discord::WebSocket::Packet.new(0_i64, 1_i64, IO::Memory.new(%("foo")), "test")
      packet.to_json.should eq json
    end

    it "parses" do
      json = %({"op":0,"s":1,"d":"foo","t":"test"})
      packet = Discord::WebSocket::Packet.from_json(json)
      packet.opcode.should eq 0
      packet.sequence.should eq 1
      packet.data.to_s.should eq %("foo")
      packet.event_type.should eq "test"
    end
  end

  it ".shard_id" do
    part = 3_u64 << 22
    shard = Discord.shard_id(part, 2)
    shard.should eq 1
  end
end
