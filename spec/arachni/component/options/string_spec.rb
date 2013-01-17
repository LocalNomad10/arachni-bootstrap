require_relative '../../../spec_helper'

describe Arachni::Component::Options::String do
    before( :all ) do
        @opt = Arachni::Component::Options::String.new( '' )
    end

    describe '#valid?' do
        it 'should return true' do
            @opt.valid?( 'test' ).should be_true
            @opt.valid?( 999 ).should be_true
            @opt.valid?( true ).should be_true
        end
        context 'when required but empty' do
            it 'should return false' do
                @opt.class.new( '', [true] ).valid?( nil ).should be_false
            end
        end
    end

    describe '#normalize' do
        it 'should return a string representation of the value' do
            @opt.normalize( 'test' ).should == 'test'
        end
        context 'when it is a file:// URL' do
            it 'should use that file\'s contents as a value' do
                @opt.normalize( 'file://' + __FILE__ ).should == IO.read( __FILE__ )
            end
        end
    end

    describe '#type' do
        it 'should return the option type as a string' do
            @opt.type.should == 'string'
        end
    end

end
