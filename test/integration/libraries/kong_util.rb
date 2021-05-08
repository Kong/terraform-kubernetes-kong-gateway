require 'net/http'
require 'uri'

def wait(url, max=500, token='password')
  count = 0
  while count <= max
    begin
      uri = URI.parse(url)
      request = Net::HTTP::Get.new(uri)
      request['Kong-Admin-Token'] = token
      req_options = {
        use_ssl: uri.scheme == 'https',
        verify_mode: OpenSSL::SSL::VERIFY_NONE
      }
      response = Net::HTTP.start(uri.hostname, uri.port, req_options).request(request)
      raise "Bad response from kong gateway: #{response.code}" if response.code.to_i != 200

      raise 'empty cluster body' if JSON.parse(response.body).empty?

      break
    rescue Exception => e
      count += 1
      if count == max
        raise "There was an issue #{e.inspect}"
      end
      sleep 1
      next
    end
  end
end

def post(url, data, token)
  uri = URI.parse(url)
  request = Net::HTTP::Post.new(uri)
  request['Kong-Admin-Token'] = token
  req_options = {
    use_ssl: uri.scheme == 'https',
    verify_mode: OpenSSL::SSL::VERIFY_NONE
  }
  request.set_form_data(data)
  Net::HTTP.start(uri.hostname, uri.port, req_options).request(request)
end
