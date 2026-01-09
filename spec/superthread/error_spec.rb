# frozen_string_literal: true

RSpec.describe Superthread::Error do
  it 'is a StandardError' do
    expect(described_class.new).to be_a(StandardError)
  end
end

RSpec.describe Superthread::ConfigurationError do
  it 'is a Superthread::Error' do
    expect(described_class.new).to be_a(Superthread::Error)
  end
end

RSpec.describe Superthread::ApiError do
  subject(:error) { described_class.new('Not found', status: 404, body: { error: 'Card not found' }) }

  it 'is a Superthread::Error' do
    expect(error).to be_a(Superthread::Error)
  end

  it 'stores the status code' do
    expect(error.status).to eq(404)
  end

  it 'stores the response body' do
    expect(error.body).to eq({ error: 'Card not found' })
  end

  it 'includes status in message' do
    expect(error.message).to include('Not found')
  end
end

RSpec.describe Superthread::AuthenticationError do
  it 'is an ApiError' do
    expect(described_class.new('Unauthorized')).to be_a(Superthread::ApiError)
  end
end

RSpec.describe Superthread::NotFoundError do
  it 'is an ApiError' do
    expect(described_class.new('Not found')).to be_a(Superthread::ApiError)
  end
end

RSpec.describe Superthread::ValidationError do
  it 'is an ApiError' do
    expect(described_class.new('Invalid params')).to be_a(Superthread::ApiError)
  end
end

RSpec.describe Superthread::RateLimitError do
  it 'is an ApiError' do
    expect(described_class.new('Too many requests')).to be_a(Superthread::ApiError)
  end
end

RSpec.describe Superthread::PathValidationError do
  it 'is a Superthread::Error' do
    expect(described_class.new('Invalid path')).to be_a(Superthread::Error)
  end
end
