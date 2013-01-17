# encoding: utf-8
require_relative '../../spec_helper'

describe Arachni::Module::Utilities do

    before( :all ) do
        @utils = Arachni::Module::Utilities
    end

    describe '#read_file' do
        it 'should read a file from a directory with the same name as the caller and return an array of stripped lines' do
            filename = 'read_file.txt'
            filepath = File.expand_path( File.dirname( __FILE__ ) ) + '/utilities_spec/' + filename

            @utils.read_file( filename ).join( "\n" ).should == IO.read( filepath ).strip
        end

        context 'if a block is given' do
            it 'should read a file from a directory with the same name as the caller one stripped line at a time' do
                filename = 'read_file.txt'
                filepath = File.expand_path( File.dirname( __FILE__ ) ) + '/utilities_spec/' + filename

                lines = []
                @utils.read_file( filename ){ |line| lines << line }

                lines.join( "\n" ).should == IO.read( filepath ).strip
            end
        end
    end
end
