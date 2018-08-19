module GocdClient
  class Util
    def self.download_file(url, path, username=nil, password=nil)
      uri = URI(url)
      SLogger.instance.debug("starting download of #{url} to #{path}")
  
      total_bytesize = 0
      http = Net::HTTP.new(uri.host, uri.port)
      if uri.kind_of?(URI::HTTPS)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      else
        http.use_ssl = false
      end 
  
      request = Net::HTTP::Get.new(uri.request_uri)
      request.basic_auth(username, password) if username || password
      http.request(request) do |response|
        File.open(path, 'w') do |io|
          response.read_body do |chunk|
            total_bytesize += chunk.bytesize
            SLogger.instance.debug("downloaded #{total_bytesize} bytes total")
            io.write(chunk)
          end
        end
      end
      
      SLogger.instance.debug("finished downloading #{total_bytesize} bytes total")
    end
  end
end