module Kirschtorte
  class Client
    def initialize config 
      connection = YAML.load(IO.read config)
      @api_host = connection["host"]
      @api_key = connection["api_key"]
      @default_headers = {
        'Accept' => "application/vnd.abby.normal.v1",
        'Authorization' => "Token token=#{@api_key}",
      }
    end

    def submit_request options
      resource = options[:resource] || ''
      method = options[:method] || :post
      headers = options[:headers] || {}
      body = options[:body] || {}

      uri = URI("#{@api_host}#{resource}")

      case method
      when :get
        request = Net::HTTP::Get.new(uri.path)
        @default_headers.merge(headers).each do |h, v|
          request[h] = v
        end
      when :post
        request = Net::HTTP::Post.new(uri.path)
        @default_headers.merge(headers).each do |h, v|
          request[h] = v
        end
        request.set_form_data(body)
      when :put
        request = Net::HTTP::Post.new(uri.path)
        @default_headers.merge(headers).each do |h, v|
          request[h] = v
        end
        request['_method'] = 'put'
        request.set_form_data(body)
      end

      http = Net::HTTP.new(uri.hostname, uri.port)
      http.use_ssl = true

      response = http.request(request)

      if response.body
        JSON.parse(response.body, :symbolize_names => true)
      else
        {}
      end
    end
  end
end
