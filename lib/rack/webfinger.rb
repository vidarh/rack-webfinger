# frozen_string_literal: true

require 'rack'
require 'json'
require_relative "webfinger/version"

module Rack
  class Webfinger
    def initialize(data_provider)
      @data_provider = data_provider
    end

    def not_found = [404, { 'content-type' => 'text/plain' }, ['Resource not found']]
            
    def call(env)
      request = Rack::Request.new(env)

      return not_found if request.path != '/.well-known/webfinger'
      
      resource = request.params['resource']

      if !resource
        return [400, { 'content-type' => 'text/plain' }, ['Missing resource parameter']]
      end

      # We need this because Rack's handling of the query string by default overwrites
      # subsequent 'rel' parameters.

      query_params = Rack::Utils.parse_query(env['QUERY_STRING'])
      rel_params = Array(query_params['rel'])

      data = @data_provider.call(resource, rel_params)
          
      return not_found if !data

      response_data = {
        subject: resource,
        aliases: data[:aliases],
        links: data[:links]
      }
      filtered_data = filter_by_rel(response_data, rel_params)

      [200,
        { 'content-type' => 'application/jrd+json' },
        [JSON.generate(filtered_data)]
      ]
    end
    
    private

    def filter_by_rel(data, rel_params)
      return data if rel_params.empty?
      
      data.merge(links: data[:links].select { |link| rel_params.include?(link[:rel]) })
    end
  end
end
