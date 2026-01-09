# frozen_string_literal: true

RSpec.describe Superthread::Client do
  subject(:client) { described_class.new }

  before do
    Superthread.configure do |config|
      config.api_key = 'test_api_key'
    end
  end

  describe '#initialize' do
    it 'initializes all resources' do
      expect(client.users).to be_a(Superthread::Resources::Users)
    end
  end

  describe 'resource accessors' do
    it 'provides users resource' do
      expect(client.users).to be_a(Superthread::Resources::Users)
    end

    it 'provides cards resource' do
      expect(client.cards).to be_a(Superthread::Resources::Cards)
    end

    it 'provides boards resource' do
      expect(client.boards).to be_a(Superthread::Resources::Boards)
    end

    it 'provides projects resource' do
      expect(client.projects).to be_a(Superthread::Resources::Projects)
    end

    it 'provides spaces resource' do
      expect(client.spaces).to be_a(Superthread::Resources::Spaces)
    end

    it 'provides comments resource' do
      expect(client.comments).to be_a(Superthread::Resources::Comments)
    end

    it 'provides pages resource' do
      expect(client.pages).to be_a(Superthread::Resources::Pages)
    end

    it 'provides notes resource' do
      expect(client.notes).to be_a(Superthread::Resources::Notes)
    end

    it 'provides sprints resource' do
      expect(client.sprints).to be_a(Superthread::Resources::Sprints)
    end

    it 'provides search resource' do
      expect(client.search).to be_a(Superthread::Resources::Search)
    end

    it 'provides tags resource' do
      expect(client.tags).to be_a(Superthread::Resources::Tags)
    end
  end
end
