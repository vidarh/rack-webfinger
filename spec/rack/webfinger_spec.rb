require 'rspec'
require 'rack/test'
require 'rack/webfinger'

RSpec.describe Rack::Webfinger do
  include Rack::Test::Methods

  let(:non_filtering_provider) do
    lambda do |resource, _rel_params|
      if resource == 'user@example.com'
        {
          aliases: ['https://example.com/user', 'https://example.com/user/profile'],
          links: [
            { rel: 'http://webfinger.net/rel/profile-page', type: 'text/html', href: 'https://example.com/user' },
            { rel: 'http://schemas.google.com/g/2010#updates-from', type: 'application/atom+xml', href: 'https://example.com/user/feed' }
          ]
        }
      end
    end
  end

  let(:filtering_provider) do
    lambda do |resource, rel_params|
      if resource == 'user@example.com'
        links = [
          { rel: 'http://webfinger.net/rel/profile-page', type: 'text/html', href: 'https://example.com/user' },
          { rel: 'http://schemas.google.com/g/2010#updates-from', type: 'application/atom+xml', href: 'https://example.com/user/feed' }
        ]
        p rel_params
        filtered_links = rel_params.empty? ? links : links.select do |link|
          rel_params.include?(link[:rel])
        end
        {
          aliases: ['https://example.com/user', 'https://example.com/user/profile'],
          links: filtered_links
        }
      end
    end
  end

  context 'with non-filtering data provider' do
    let(:app) { Rack::Webfinger.new(non_filtering_provider) }

    it 'returns all links when no rel parameter is provided' do
      get '/.well-known/webfinger?resource=user@example.com'
      expect(last_response.status).to eq(200)
      json_response = JSON.parse(last_response.body)
      expect(json_response['links'].size).to eq(2)
    end

    it 'filters links in the application when rel parameter is provided' do
      get '/.well-known/webfinger?resource=user@example.com&rel=http://webfinger.net/rel/profile-page'
      expect(last_response.status).to eq(200)
      json_response = JSON.parse(last_response.body)
      expect(json_response['links'].size).to eq(1)
      expect(json_response['links'][0]['rel']).to eq('http://webfinger.net/rel/profile-page')
    end
  end

  context 'with filtering data provider' do
    let(:app) { Rack::Webfinger.new(filtering_provider) }

    it 'returns all links when no rel parameter is provided' do
      get '/.well-known/webfinger?resource=user@example.com'
      expect(last_response.status).to eq(200)
      json_response = JSON.parse(last_response.body)
      expect(json_response['links'].size).to eq(2)
    end

    it 'returns filtered links when rel parameter is provided' do
      get '/.well-known/webfinger?resource=user@example.com&rel=http://webfinger.net/rel/profile-page'
      expect(last_response.status).to eq(200)
      json_response = JSON.parse(last_response.body)
      expect(json_response['links'].size).to eq(1)
      expect(json_response['links'][0]['rel']).to eq('http://webfinger.net/rel/profile-page')
    end

    it 'handles multiple rel parameters correctly' do
      get '/.well-known/webfinger?resource=user@example.com&rel=http://webfinger.net/rel/profile-page&rel=http://schemas.google.com/g/2010%23updates-from'
      expect(last_response.status).to eq(200)
      json_response = JSON.parse(last_response.body)
      expect(json_response['links'].size).to eq(2)
    end
  end

  context 'general behavior' do
    let(:app) { Rack::Webfinger.new(non_filtering_provider) }

    it 'returns 404 for non-webfinger paths' do
      get '/some-other-path'
      expect(last_response.status).to eq(404)
    end

    it 'returns 400 for missing resource parameter' do
      get '/.well-known/webfinger'
      expect(last_response.status).to eq(400)
    end

    it 'returns 404 for non-existent resource' do
      get '/.well-known/webfinger?resource=nonexistent@example.com'
      expect(last_response.status).to eq(404)
    end

    it 'sets subject to the provided resource' do
      get '/.well-known/webfinger?resource=user@example.com'
      json_response = JSON.parse(last_response.body)
      expect(json_response['subject']).to eq('user@example.com')
    end
  end
end
