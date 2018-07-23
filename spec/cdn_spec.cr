require "./spec_helper"

describe Discord::CDN do
  it "builds a custom emoji URL" do
    url = Discord::CDN.custom_emoji(1, :png, 16)
    url.should eq "https://cdn.discordapp.com/emojis/1.png?size=16"
  end

  it "builds a guild icon URL" do
    url = Discord::CDN.guild_icon(1, "hash", :png, 16)
    url.should eq "https://cdn.discordapp.com/icons/1/hash.png?size=16"
  end

  it "builds a guild splash URL" do
    url = Discord::CDN.guild_splash(1, "hash", :png, 16)
    url.should eq "https://cdn.discordapp.com/splashes/1/hash.png?size=16"
  end

  it "builds a default user avatar URL" do
    url = Discord::CDN.default_user_avatar("0001")
    url.should eq "https://cdn.discordapp.com/embed/avatars/1.png"

    url = Discord::CDN.default_user_avatar("0007")
    url.should eq "https://cdn.discordapp.com/embed/avatars/2.png"
  end

  describe "user_avatar" do
    it "builds a user avatar URL" do
      url = Discord::CDN.user_avatar(1, "hash", :png, 16)
      url.should eq "https://cdn.discordapp.com/avatars/1/hash.png?size=16"
    end

    context "without format" do
      it "detects an animated avatar" do
        url = Discord::CDN.user_avatar(1, "a_hash", 16)
        url.should eq "https://cdn.discordapp.com/avatars/1/a_hash.gif?size=16"
      end

      it "defaults to webp" do
        url = Discord::CDN.user_avatar(1, "hash", 16)
        url.should eq "https://cdn.discordapp.com/avatars/1/hash.webp?size=16"
      end
    end
  end

  it "builds an application icon URL" do
    url = Discord::CDN.application_icon(1, "hash", :png, 16)
    url.should eq "https://cdn.discordapp.com/app-icons/1/hash.png?size=16"
  end

  it "raises on an invalid size" do
    expect_raises(ArgumentError, "Size 17 is not between 16 and 2048 and a power of 2") do
      Discord::CDN.custom_emoji(1, :png, 17)
    end

    expect_raises(ArgumentError, "Size 0 is not between 16 and 2048 and a power of 2") do
      Discord::CDN.custom_emoji(1, :png, 0)
    end
  end
end
