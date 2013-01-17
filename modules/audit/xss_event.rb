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
# It injects a string and checks if it appears inside an event attribute of any HTML tag.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.3
#
# @see http://cwe.mitre.org/data/definitions/79.html
# @see http://ha.ckers.org/xss.html
# @see http://secunia.com/advisories/9716/
#
class Arachni::Modules::XSSEvent < Arachni::Module::Base

    EVENT_ATTRS = [
        'onload',
        'onunload',
        'onblur',
        'onchange',
        'onfocus',
        'onreset',
        'onselect',
        'onsubmit',
        'onabort',
        'onkeydown',
        'onkeypress',
        'onkeyup',
        'onclick',
        'ondblclick',
        'onmousedown',
        'onmousemove',
        'onmouseout',
        'onmouseover',
        'onmouseup',
        'src' # not an event but it'll work
    ]

    def self.strings
        @strings ||= [
            ";arachni_xss_in_element_event=" + seed + '//',
            "\";arachni_xss_in_element_event=" + seed + '//',
            "';arachni_xss_in_element_event=" + seed + '//'
        ]
    end

    def run
        self.class.strings.each do |str|
            audit( str, format: [ Format::APPEND ] ) do |res, opts|
                check_and_log( res, str, opts )
            end
        end
    end

    def check_and_log( res, injected, opts )
        return if !res.body || !res.body.include?( injected )

        doc = Nokogiri::HTML( res.body )
        EVENT_ATTRS.each do |attr|
            doc.xpath( "//*[@#{attr}]" ).each do |elem|
                if elem.attributes[attr].to_s.include?( injected )
                    log( opts.merge( id: elem.to_s ), res )
                end
            end
        end
    end

    def self.info
        {
            name:        'XSS in HTML element event attribute',
            description: %q{Cross-Site Scripting in event tag of HTML element.},
            elements:    [Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.1.3',
            references:  {
                'ha.ckers' => 'http://ha.ckers.org/xss.html',
                'Secunia'  => 'http://secunia.com/advisories/9716/'
            },
            targets:     %w(Generic),
            issue:       {
                name:            %q{Cross-Site Scripting in event tag of HTML element.},
                description:     %q{Unvalidated user input is being embedded inside an HMTL event element such as "onmouseover".
    This makes Cross-Site Scripting attacks much easier to mount since the user input
    lands in code waiting to be executed.},
                tags:            %w(xss event injection regexp dom attribute),
                cwe:             '79',
                severity:        Severity::HIGH,
                cvssv2:          '9.0',
                remedy_guidance: 'User inputs must be validated and filtered
    before being included in executable code or not be included at all.',
            }

        }
    end

end
