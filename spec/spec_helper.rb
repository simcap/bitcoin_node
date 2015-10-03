require File.expand_path('../lib/bitcoin_node.rb', __dir__)

require 'celluloid/io'
require 'pry'
require 'awesome_print'

class WrapperActor
  include Celluloid::IO
  execute_block_on_receiver :wrap

  def wrap
    yield
  end
end

def random_port
  port = 12_000 + Random.rand(1024)
end

def within_io_actor(&block)
  actor = WrapperActor.new
  actor.wrap(&block)
ensure
  actor.terminate if actor.alive? rescue nil
end
