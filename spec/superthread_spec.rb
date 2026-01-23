# frozen_string_literal: true

RSpec.describe Superthread do
  it "has a version number" do
    expect(Superthread::VERSION).not_to be_nil
  end

  it "has a version matching semver format" do
    expect(Superthread::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end
end
