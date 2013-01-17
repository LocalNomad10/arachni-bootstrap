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

module Arachni

require Options.dir['lib'] + 'rpc/server/output'

module RPC

#
# Dispatcher node class, helps maintain a list of all available Dispatchers in the grid
# and announce itself to neighbouring Dispatchers.
#
# As soon as a new Node is fired up it checks-in with its neighbour and grabs
# a list of all available peers.
#
# As soon as it receives the peer list it then announces itself to them.
#
# Upon convergence there will be a grid of Dispatchers each one with its own copy
# of all available Dispatcher URLs.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Server::Dispatcher::Node
    include UI::Output

    DEFAULT_PING_INTERVAL = 60

    #
    # Initializes the node by:
    # * Adding the neighbour (if the user has supplied one) to the peer list
    # * Getting the neighbour's peer list and appending them to its own
    # * Announces itself to the neighbour and instructs it to propagate our URL to the others
    #
    # @param    [Arachni::Options]    opts
    # @param    [String]              logfile   were to send the output
    #
    def initialize( opts, logfile = nil )
        @opts = opts
        @url  = "#{@opts.rpc_address}:#{@opts.rpc_port.to_s}"

        reroute_to_file( logfile ) if logfile

        print_status 'Initing grid node...'

        @dead_nodes = []
        @neighbours = Set.new
        @nodes_info_cache = []

        if neighbour = @opts.neighbour
            # add neighbour and announce him to everyone
            add_neighbour( neighbour, true )

            # grab the neighbour's neighbours
            peer = connect_to_peer( neighbour )
            peer.neighbours do |urls|
                fail "Neighbour '#{neighbour}' is unreachable." if urls.rpc_exception?
                urls.each { |url| @neighbours << url if url != @url }
            end
        end

        print_status( 'Node ready.' )

        log_updated_neighbours

        ::EM.add_periodic_timer( @opts.node_ping_interval || DEFAULT_PING_INTERVAL ) {
            ping
            check_for_comebacks
        }
    end

    #
    # Adds a neighbour to the peer list
    #
    # @param    [String]    node_url    URL of a neighbouring node
    # @param    [Boolean]   propagate   wether or not to announce the new node
    #                                    to the ones in the peer list
    #
    def add_neighbour( node_url, propagate = false )
        # we don't want ourselves in the Set
        return false if node_url == @url
        return false if @neighbours.include?( node_url )

        print_status 'Adding neighbour: ' + node_url

        @neighbours << node_url
        log_updated_neighbours
        announce( node_url ) if propagate

        connect_to_peer( node_url ).add_neighbour( @url, propagate ) do |res|
            next if !res.rpc_exception?
            add_dead_neighbour( node_url )
            print_status "Neighbour seems dead: #{node_url}"
        end
        true
    end

    #
    # Returns all neighbour/node/peer URLs
    #
    # @return   [Array]
    #
    def neighbours
        @neighbours.to_a
    end

    def neighbours_with_info( &block )
        fail "This method requires a block!" if !block_given?

        @neighbours_cmp = ''
        if @nodes_info_cache.empty? || @neighbours_cmp != neighbours.to_s

            @neighbours_cmp = neighbours.to_s

            ::EM::Iterator.new( neighbours ).map( proc {
                |neighbour, iter|

                connect_to_peer( neighbour ).info {
                    |info|

                    if info.rpc_exception?
                        print_info "Neighbour seems dead: #{neighbour}"
                        add_dead_neighbour( neighbour )
                        log_updated_neighbours

                        iter.return( nil )
                    else
                        iter.return( info )
                    end
                }
            }, proc {
                |nodes|
                @nodes_info_cache = nodes.compact
                block.call( @nodes_info_cache )
            })
        else
            block.call( @nodes_info_cache )
        end
    end

    #
    # Returns node specific info:
    # * Bandwidth Pipe ID
    # * Weight
    # * Nickname
    # * Cost
    #
    # @return    [Hash]
    #
    def info
        {
            'url'        => @url,
            'pipe_id'    => @opts.pipe_id,
            'weight'     => @opts.weight,
            'nickname'   => @opts.nickname,
            'cost'       => @opts.cost
        }
    end

    def alive?
        true
    end

    private

    def remove_neighbour( node_url )
        @neighbours -= [node_url]
    end

    def add_dead_neighbour( url )
        remove_neighbour( url )
        @dead_nodes << url
    end

    def log_updated_neighbours
        print_info 'Updated neighbours:'

        if !neighbours.empty?
            neighbours.each { |node| print_info( '---- ' + node ) }
        else
            print_info '<empty>'
        end
    end

    def ping
        neighbours.each do |neighbour|
            connect_to_peer( neighbour ).alive? do |res|
                next if !res.rpc_exception?
                add_dead_neighbour( neighbour )
                print_status "Found dead neighbour: #{neighbour} "
            end
        end
    end

    def check_for_comebacks
        @dead_nodes.dup.each do |url|
            neighbour = connect_to_peer( url )
            neighbour.alive? do |res|
                next if res.rpc_exception?

                print_status "Dispatcher came back to life: #{url}"
                ([@url] | neighbours).each do |node|
                    neighbour.add_neighbour( node ){}
                end

                add_neighbour( url )
                @dead_nodes -= [url]
            end
        end
    end

    #
    # Announces the node to the ones in the peer list
    #
    # @param    [String]    node    URL
    #
    def announce( node )
        print_status "Advertising: #{node}"

        neighbours.each do |peer|
            next if peer == node

            print_info '---- to: ' + peer
            connect_to_peer( peer ).add_neighbour( node ) do |res|
                add_dead_neighbour( peer ) if res.rpc_exception?
            end
        end
    end

    def connect_to_peer( url )
        Client::Dispatcher.new( @opts, url ).node
    end

end
end
end
