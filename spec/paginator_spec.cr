require "./spec_helper"

describe Discord::Paginator do
  context "direction up" do
    it "requests all pages until empty" do
      data = {
        [1, 2, 3],
        [4, 5],
        [] of Int32,
        [6, 7],
      }

      index = 0
      paginator = Discord::Paginator(Int32).new(nil, :down) do |last_page|
        if last_page
          last_page.should eq data[index - 1]
        end
        index += 1
        data[index - 1]
      end

      paginator.to_a.should eq [1, 2, 3, 4, 5]
    end
  end

  context "direction down" do
    it "requests all pages until empty" do
      data = {
        [6, 7],
        [4, 5],
        [] of Int32,
        [1, 2, 3],
      }

      index = 0
      paginator = Discord::Paginator(Int32).new(nil, :up) do |last_page|
        if last_page
          last_page.should eq data[index - 1]
        end
        index += 1
        data[index - 1]
      end

      paginator.to_a.should eq [7, 6, 5, 4]
    end
  end

  it "only returns up to limit items" do
    data = {
      [1, 2, 3],
      [4, 5],
      [] of Int32,
    }

    index = 0
    paginator = Discord::Paginator(Int32).new(2, :down) do |last_page|
      index += 1
      data[index - 1]
    end

    paginator.to_a.should eq [1, 2]
  end
end
