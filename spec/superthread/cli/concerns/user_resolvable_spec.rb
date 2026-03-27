# frozen_string_literal: true

require "spec_helper"

RSpec.describe Superthread::Cli::Concerns::UserResolvable do
  let(:test_class) do
    Class.new do
      include Superthread::Cli::Concerns::UserResolvable

      attr_accessor :client

      def looks_like_id?(value)
        value.match?(/\A[a-zA-Z0-9_-]+\z/) && value.length <= 36
      end

      def workspace_id
        "test_workspace"
      end

      public :resolve_user
    end
  end

  let(:client) { instance_double(Superthread::Client) }
  let(:users_resource) { instance_double(Superthread::Resources::Users) }
  let(:instance) do
    obj = test_class.new
    obj.client = client
    obj
  end

  let(:current_user) do
    Superthread::Models::User.new(id: "u123abc", display_name: "Test User", email: "test@example.com")
  end

  let(:members) do
    [
      Superthread::Models::User.new(user_id: "u123abc", display_name: "Test User", email: "test@example.com"),
      Superthread::Models::User.new(user_id: "u456def", display_name: "Another User", email: "another@example.com")
    ]
  end

  before do
    allow(client).to receive(:users).and_return(users_resource)
    allow(users_resource).to receive(:members).with("test_workspace").and_return(members)
  end

  describe "#resolve_user" do
    it "returns nil for nil input" do
      expect(instance.resolve_user(nil)).to be_nil
    end

    it "returns ID directly when ref looks like an ID" do
      expect(instance.resolve_user("u123abc")).to eq("u123abc")
    end

    it "resolves display name to user_identifier" do
      expect(instance.resolve_user("Another User")).to eq("u456def")
    end

    it "raises Thor::Error when name not found" do
      expect { instance.resolve_user("Nobody Here") }.to raise_error(Thor::Error, /User not found/)
    end

    context "when ref is 'me'" do
      before do
        allow(users_resource).to receive(:me).and_return(current_user)
      end

      it "resolves 'me' to the current user's identifier" do
        expect(instance.resolve_user("me")).to eq("u123abc")
      end

      it "resolves 'Me' case-insensitively" do
        expect(instance.resolve_user("Me")).to eq("u123abc")
      end

      it "resolves 'ME' case-insensitively" do
        expect(instance.resolve_user("ME")).to eq("u123abc")
      end
    end
  end
end
