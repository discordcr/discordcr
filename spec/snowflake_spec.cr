require "./spec_helper"

describe Discord::Snowflake do
  describe Discord::DISCORD_EPOCH do
    it "is 2015-01-01" do
      expected = Time.new(2015, 1, 1, location: Time::Location::UTC)
      Discord::DISCORD_EPOCH.should eq expected.epoch_ms
    end
  end

  it "#to_json" do
    snowflake = Discord::Snowflake.new(0_u64)
    json = JSON.build do |builder|
      snowflake.to_json(builder)
    end
    json.should eq %("0")
  end

  it ".from_json" do
    parser = JSON::PullParser.new(%("0"))
    snowflake = Discord::Snowflake.new(parser)
    snowflake.value.should eq 0_u64
  end

  describe Array(Discord::Snowflake) do
    it "can be sorted" do
      snowflake_a = Discord::Snowflake.new(2_u64)
      snowflake_b = Discord::Snowflake.new(1_u64)
      snowflake_c = Discord::Snowflake.new(0_u64)

      array = [snowflake_a, snowflake_b, snowflake_c]
      array.sort.should eq [snowflake_c, snowflake_b, snowflake_a]
    end
  end

  describe "#creation_time" do
    it "returns the time the snowflake was created" do
      time = Time.new(2018, 4, 18)
      snowflake = Discord::Snowflake.new(time)
      snowflake.creation_time.should eq time
    end
  end

  it "compares to uint64" do
    snowflake = Discord::Snowflake.new(1_u64)
    (snowflake == 1_u64).should be_true
    (snowflake == 0_u64).should be_false
  end
end
