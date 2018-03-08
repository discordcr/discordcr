require "./spec_helper"

def it_parses_message(string, into expected)
  it "parses #{string.inspect} into #{expected}" do
    parsed = Discord::Mention.parse(string)
    parsed.should eq expected
  end
end

describe Discord::Mention do
  describe ".parse" do
    it_parses_message(
      "<@123><@!456>",
      into: [
        Discord::Mention::User.new(123_u64, 0, 6),
        Discord::Mention::User.new(456_u64, 6, 7),
      ]
    )

    it_parses_message(
      "<@&123>",
      into: [Discord::Mention::Role.new(123_u64, 0, 6)])

    it_parses_message(
      "<#123>",
      into: [Discord::Mention::Channel.new(123_u64, 0, 6)])

    it_parses_message(
      "<:foo:123><a:bar:456>",
      into: [
        Discord::Mention::Emoji.new(false, "foo", 123_u64, 0, 10),
        Discord::Mention::Emoji.new(true, "bar", 456_u64, 10, 11),
      ]
    )

    it_parses_message(
      "@everyone@here",
      into: [
        Discord::Mention::Everyone.new(0),
        Discord::Mention::Here.new(9),
      ]
    )

    context "with invalid mentions" do
      it_parses_message(
        "<<@123<@?123><#123<:foo:123<b:foo:123><@abc><@!abc>",
        into: [] of Discord::Mention)
    end
  end
end
