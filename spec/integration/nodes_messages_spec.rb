require 'spec_helper'

describe 'Two nodes exchanging messages' do

  it 'communicates version correctly' do

    server = LocalServer.new

    LocalClient.send_message('hello')
    LocalClient.send_message('goodbye')
    sleep(1)

    server.terminate
  end

end
