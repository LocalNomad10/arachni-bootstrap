require_relative '../../../spec_helper'

describe Arachni::Component::Options::Bool do
    before( :all ) do
        @opt    = Arachni::Component::Options::Bool
        @trues  = [ true, 'y', 'yes', '1', 1, 't', 'true', 'on' ]
        @falses = [ false, 'n', 'no', '0', 0, 'f', 'false', 'off', '' ]
    end

    describe '#valid?' do
        context 'when the value is valid' do
            it 'should return true' do
                @trues.each { |v| @opt.new( '' ).valid?( v ).should be_true }
            end
        end
        context 'when the value is not valid' do
            it 'should return false' do
                @opt.new( '' ).valid?( 'dds' ).should be_false
            end
        end
        context 'when required but empty' do
            it 'should return false' do
                @opt.new( '', [true] ).valid?( nil ).should be_false
            end
        end
    end

    describe '#normalize' do
        it 'should convert the string input into a boolean value' do
            @trues.each { |v| @opt.new( '' ).normalize( v ).should be_true }
            @falses.each { |v| @opt.new( '' ).normalize( v ).should be_false }
        end
    end

    describe '#true?' do
        context 'when the value option represents true' do
            it 'should return true' do
                @trues.each { |v| @opt.new( '' ).true?( v ).should be_true }
            end
        end
        context 'when the value option represents false' do
            it 'should return false' do
                @trues.each { |v| @opt.new( '' ).true?( v ).should be_true }
            end
        end
    end

    describe '#false?' do
        context 'when the value option represents false' do
            it 'should return true' do
                @falses.each { |v| @opt.new( '' ).false?( v ).should be_true }
            end
        end
        context 'when the value option represents true' do
            it 'should return false' do
                @falses.each { |v| @opt.new( '' ).false?( v ).should be_true }
            end
        end
    end

    describe '#type' do
        it 'should return the option type as a string' do
            @opt.new( '' ).type.should == 'bool'
        end
    end

end
