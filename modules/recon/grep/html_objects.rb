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

#
# Looks for HTML "object" tags.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.2
#
class Arachni::Modules::HTMLObjects < Arachni::Module::Base

    def self.regexp
        @regexp ||= /<object(.*)>(.*)<\/object>/im
    end

    def run
        match_and_log( self.class.regexp ) { |m| m && !m.empty? }
    end

    def self.info
        {
            name:        'HTML objects',
            description: %q{Greps pages for HTML objects.},
            elements:    [ Element::BODY ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.1',
            targets:     %w(Generic),
            issue:       {
                name:     %q{Found an HTML object.},
                cwe:      '200',
                severity: Severity::INFORMATIONAL
            }
        }
    end

end
