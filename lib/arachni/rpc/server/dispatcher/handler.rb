=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

module Arachni::RPC

#
# Base class and namespace for all RPCD/Dispatcher handlers.
#
# == RPC accessibility
#
# Only PUBLIC methods YOU have defined will be accessible over RPC.
#
# == Blocking operations
#
# Please try to avoid blocking operations as they will block the main Reactor loop.
#
# However, if you really need to perform such operations, you can update the
# relevant methods to expect a block and then pass the desired return value to that block
# instead of returning it the usual way.
#
# This will result in the method's payload to be deferred into a Thread of its own.
#
# In addition, you can use the {#defer} and {#run_asap} methods is you need more
# control over what gets deferred and general scheduling.
#
# == Asynchronous operations
#
# Methods which perform async operations should expect a block and pass their
# results to that block instead of returning a value.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Server::Dispatcher::Handler

    attr_reader :opts
    attr_reader :dispatcher

    def initialize( opts, dispatcher )
        @opts       = opts
        @dispatcher = dispatcher
    end

    # @return   [Server::Dispatcher::Node]  local node
    def node
        dispatcher.instance_eval { @node }
    end

    #
    # Performs an asynchronous map operation over all running instances.
    #
    # @param [Proc]  each    block to be passed {Client::Instance} and {::EM::Iterator}
    # @param [Proc]  after   block to be passed the Array of results
    #
    def map_instances( each, after )
        wrap_each = proc do |instance, iterator|
            each.call( connect_to_instance( instance ), iterator )
        end
        iterator_for( instances ).map( wrap_each, after )
    end

    #
    # Performs an asynchronous iteration over all running instances.
    #
    # @param [Proc]  block    block to be passed {Client::Instance} and {::EM::Iterator}
    #
    def each_instance( &block )
        wrap = proc do |instance, iterator|
            block.call( connect_to_instance( instance ), iterator )
        end
        iterator_for( instances ).each( &wrap )
    end

    #
    # Defers a blocking operation in order to avoid blocking the main Reactor loop.
    #
    # The operation will be run in its own Thread - DO NOT block forever.
    #
    # Accepts either 2 parameters (an +operation+ and a +callback+) or an operation
    # as a block.
    #
    # @param    [Proc]  operation   operation to defer
    # @param    [Proc]  callback    block to call with the results of the operation
    #
    # @param    [Block]  block      operation to defer
    #
    def defer( operation = nil, callback = nil, &block )
        ::EM.defer( *[operation, callback].compact, &block )
    end

    #
    # Runs a block as soon as possible in the Reactor loop.
    #
    # @param    [Block] block
    #
    def run_asap( &block )
        ::EM.next_tick( &block )
    end

    #
    # @param    [Array]    arr
    #
    # @return   [::EM::Iterator]  iterator for the provided array
    #
    def iterator_for( arr, max_concurrency = 10 )
        ::EM::Iterator.new( arr, max_concurrency )
    end

    # @return   [Array<Hash>]   all running instances
    def instances
        dispatcher.jobs.select { |j| !j['proc'].empty? }
    end

    #
    # Connects to a Dispatcher by +url+.
    #
    # @param    [String]    url
    #
    # @return   [Client::Dispatcher]
    #
    def connect_to_dispatcher( url )
        Client::Dispatcher.new( opts, url )
    end

    #
    # Connects to an Instance by +url+.
    #
    # @example
    #   connect_to_instance( url, token )
    #   connect_to_instance( url: url, token: token )
    #   connect_to_instance( 'url' => url, 'token' => token )
    #
    # @param    [Vararg]    args
    #
    # @return   [Client::Instance]
    #
    def connect_to_instance( *args )
        url = token = nil

        if args.size == 2
            url, token = *args
        elsif args.first.is_a? Hash
            options = args.first
            url     = options['url'] || options[:url]
            token   = options['token'] || options[:token]
        end

        Client::Instance.new( opts, url, token )
    end

end
end
