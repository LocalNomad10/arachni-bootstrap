require_relative '../../../spec_helper'

describe name_from_filename do
    include_examples 'module'

    def self.targets
        %w(Generic)
    end

    def self.elements
        [ Element::BODY ]
    end

    def issue_count
        6
    end

    easy_test
end
