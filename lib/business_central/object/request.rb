# frozen_string_literal: true

module BusinessCentral
  module Object
    class Request
      class << self
        def get(client, url)
          request(:get, client, url)
        end

        def post(client, url, params)
          request(:post, client, url, params: params)
        end

        def patch(client, url, etag, params)
          request(:patch, client, url, etag: etag, params: params)
        end

        def delete(client, url, etag)
          request(:delete, client, url, etag: etag)
        end

        def convert(request = {})
          result = {}
          request.each do |key, value|
            result[key.to_s.to_camel_case] = value if key.is_a? Symbol
            result[key.to_s] = value if key.is_a? String
          end

          result.to_json
        end

        private

        def request(method, client, url, etag: '', params: {})
          send do
            uri = URI(url)
            https = Net::HTTP.new(uri.host, uri.port)
            https.use_ssl = true
            request = Object.const_get("Net::HTTP::#{method.to_s.capitalize}").new(uri)
            request['Content-Type'] = 'application/json'
            request['Accept'] = 'application/json'
            request['If-Match'] = etag if !etag.blank?
            request.body = convert(params) if %i[post patch].include?(method)
            if client.access_token
              request['Authorization'] = "Bearer #{client.access_token.token}"
            else
              request.basic_auth(client.username, client.password)
            end
            https.request(request)
          end
        end

        def send
          request = yield
          response = Response.new(request.read_body.to_s).results

          if Response.success?(request.code.to_i)
            response
          elsif Response.deleted?(request.code.to_i)
            true
          else
            if Response.unauthorized?(request.code.to_i)
              raise UnauthorizedException
            elsif Response.not_found?(request.code.to_i)
              raise NotFoundException
            else
              if !response.fetch(:error, nil).nil?
                case response[:error][:code]
                when 'Internal_CompanyNotFound'
                  raise CompanyNotFoundException
                else
                  raise ApiException, "#{request.code} - #{response[:error][:code]} #{response[:error][:message]}"
                end
              else
                raise ApiException, "#{request.code} - API call failed"
              end
            end
          end
        end
      end
    end
  end
end
