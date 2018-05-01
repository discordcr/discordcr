require "./spec_helper"

describe Discord::REST do
  describe "#encode_tuple" do
    it "doesn't emit null values" do
      client = Discord::Client.new("foo", 0_u64)
      client.encode_tuple(foo: ["bar", 1, 2], baz: nil).should eq(%({"foo":["bar",1,2]}))
    end
  end
end
