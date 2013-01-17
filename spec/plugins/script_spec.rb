require_relative '../spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    it 'should execute a Ruby script under the scope of the running plugin' do
        options.plugins[name_from_filename] = { 'path' => spec_path + 'fixtures/script_plugin.rb' }

        run
        results_for( name_from_filename ).should == 'I\'m a script!'
    end
end
