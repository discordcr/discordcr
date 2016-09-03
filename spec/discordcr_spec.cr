require "./spec_helper"

struct StructWithSnowflake
  JSON.mapping(
    data: {type: UInt64, converter: Discord::SnowflakeConverter}
  )
end

struct StructWithMaybeSnowflake
  JSON.mapping(
    data: {type: UInt64 | Nil, converter: Discord::MaybeSnowflakeConverter}
  )
end

describe Discord do
  describe Discord::SnowflakeConverter do
    it "converts a string to u64" do
      json = %({"data":"10000000000"})

      obj = StructWithSnowflake.from_json(json)
      obj.data.should eq 10000000000
    end
  end

  describe Discord::MaybeSnowflakeConverter do
    it "converts a string to u64" do
      json = %({"data":"10000000000"})

      obj = StructWithMaybeSnowflake.from_json(json)
      obj.data.should eq 10000000000
    end

    it "converts null to nil" do
      json = %({"data":null})

      obj = StructWithMaybeSnowflake.from_json(json)
      obj.data.should eq nil
    end
  end
end
