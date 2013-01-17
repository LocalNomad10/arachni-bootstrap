class Arachni::RPC::Server::Dispatcher
class Handler::Echo < Handler

    private :instances
    public  :instances

    def test_dispatcher
        dispatcher.class == Arachni::RPC::Server::Dispatcher
    end

    def test_opts
        dispatcher.instance_eval{ @opts } == opts
    end

    def test_node
        node.class == Node
    end

    def test_map_instances( &block )
        each = proc do |instance, iterator|
            instance.opts.datastore { |store| iterator.return [instance.url, store[:token]] }
        end
        after = proc { |i| block.call Hash[i] }

        map_instances( each, after )
    end

    def test_each_instance
        i = 0
        each_instance do |instance, iterator|
            i += 1
            instance.opts.set( url: "http://stuff.com/#{i}") { |p| iterator.next }
        end
        true
    end

    def test_iterator_for
        iterator_for( instances ).class == ::EM::Iterator
    end

    def test_connect_to_dispatcher( &block )
        connect_to_dispatcher( opts.datastore[:dispatcher_url] ).alive? { |b| block.call b }
    end

    def test_connect_to_instance( *args, &block )
        connect_to_instance( *args ).framework.busy?{ |b| block.call !!b }
    end

    def test_defer( *args, &block )
        defer do
            block.call args
        end
    end

    def test_defer_two_args( *args, &block )
        defer( proc { args }, proc { |r| block.call r } )
    end

    def test_run_asap( *args, &block )
        run_asap { block.call args }
    end

    def echo( *args )
        args
    end

end
end
