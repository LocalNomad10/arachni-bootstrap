shared_examples_for "path_extractor" do
    include_examples 'component'

    before( :each ) do
        extractors.namespace.constants.each do |const|
            next if const == :Base
            extractors.namespace.send :remove_const, const
        end
        extractors.clear
    end

    def results
    end

    def text
    end

    def self.easy_test( &block )
        it "should extract the expected paths" do
            raise 'No paths provided via #results, use \':nil\' for \'nil\' results.' if !results

            actual_results.sort.should == results.sort
            instance_eval &block if block_given?
        end
    end

    def doc
        Nokogiri::HTML( text )
    end

    def actual_results
        results_for( name )
    end

    def results_for( name )
        paths = extractors[name].new.run( doc ) || []
        paths.delete( 'http://www.w3.org/TR/REC-html40/loose.dtd' )
        paths.compact.flatten
    end

    module Arachni::Parser::Extractors;end
    def extractors
        @path_extractors ||=
            ::Arachni::Component::Manager.new( options.dir['path_extractors'], Arachni::Parser::Extractors )
    end

end
