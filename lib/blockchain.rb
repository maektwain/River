require 'faraday'
require 'jsonrpc-client'

module Blockchain



  def create_connect(username, password)


    connection = Faraday.new { |connection|
      connection.adapter Faraday.default_adapter
      connection.ssl.verify = false  # This is a baaaad idea!
      connection.basic_auth(username,password)
    }

    return connection

  end

  def create_client(url,connection)

    client = JSONRPC::Client.new(url, { connection: connection })

    return client

  end









end