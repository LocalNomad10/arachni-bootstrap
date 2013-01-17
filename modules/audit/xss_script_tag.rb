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
# XSS in HTML script tag.
# It injects strings and checks if they appear inside HTML 'script' tags.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.3
#
# @see http://cwe.mitre.org/data/definitions/79.html
# @see http://ha.ckers.org/xss.html
# @see http://secunia.com/advisories/9716/
#
class Arachni::Modules::XSSScriptTag < Arachni::Module::Base

    def self.strings
        @strings ||= [
            "arachni_xss_in_script_tag_#{seed}",
            "\"arachni_xss_in_script_tag_" + seed + '"',
            "'arachni_xss_in_script_tag_" + seed + "'"
        ]
    end

    def self.opts
        @opts ||= { format: [ Format::APPEND ] }
    end

    def run
        self.class.strings.each do |str|
            audit( str, self.class.opts ) { |res, opts| check_and_log( res, str, opts ) }
        end
    end

    def check_and_log( res, injected, opts )
        # if we have no body or it doesn't contain the injected string under any
        # context there's no point in parsing the HTML to verify the vulnerability
        return if !res.body || !res.body.include?( injected )

        begin
            # see if we managed to inject a working HTML attribute to any
            # elements
            if (html_elem = Nokogiri::HTML( res.body ).css( "script" )).empty? ||
                !html_elem.to_s.include?( injected )
                return
            end

            opts[:match] = html_elem.to_s
            log( opts, res )
        end
    end

    def self.info
        {
            name:        'XSS in HTML "script" tag',
            description: %q{Injects strings and checks if they appear inside HTML 'script' tags.},
            elements:    [Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.1.3',
            references:  {
                'ha.ckers' => 'http://ha.ckers.org/xss.html',
                'Secunia'  => 'http://secunia.com/advisories/9716/'
            },
            targets:     %w(Generic),
            issue:       {
                name:            %q{Cross-Site Scripting in HTML "script" tag.},
                description:     %q{Unvalidated user input is being embedded inside a <script> element.
    This makes Cross-Site Scripting attacks much easier to mount since user input lands inside
    a trusted script.},
                tags:            %w(xss script tag regexp dom attribute injection),
                cwe:             '79',
                severity:        Severity::HIGH,
                cvssv2:          '9.0',
                remedy_guidance: 'User inputs must be validated and filtered
    before being included in executable code or not be included at all.',
            }
        }
    end

end
