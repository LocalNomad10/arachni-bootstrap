require_relative '../../../spec_helper'

describe Arachni::Component::Options::Path do
    before( :all ) do
        @opt = Arachni::Component::Options::Path.new( '' )
    end

    describe '#valid?' do
        context 'when the path exists' do
            it 'should return true' do
                @opt.valid?( __FILE__ ).should be_true
            end
        end
        context 'when the path does not exist' do
            it 'should return false' do
                @opt.valid?( __FILE__ + '22' ).should be_false
            end
        end
        context 'when required but empty' do
            it 'should return false' do
                @opt.class.new( '', [true] ).valid?( nil ).should be_false
            end
        end
    end

    describe '#type' do
        it 'should return the option type as a string' do
            @opt.type.should == 'path'
        end
    end

end
