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
# Generates a simple list of safe/unsafe URLs.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Arachni::Plugins::HealthMap < Arachni::Plugin::Base

    is_distributable

    def prepare
        wait_while_framework_running
    end

    def run
        auditstore = framework.auditstore

        sitemap  = auditstore.sitemap.map { |url| url.split( '?' ).first }.uniq
        sitemap |= issue_urls = auditstore.issues.map { |issue| issue.url }.uniq

        return if sitemap.size == 0

        issue_cnt = 0
        map = []
        sitemap.each do |url|
            next if !url

            if issue_urls.include?( url )
                map << { unsafe: url }
                issue_cnt += 1
            else
                map << { safe: url }
            end
        end

        register_results(
            map:              map,
            total:            map.size,
            safe:             map.size - issue_cnt,
            unsafe:           issue_cnt,
            issue_percentage: ((issue_cnt.to_f / map.size.to_f) * 100).round
        )
    end

    def self.merge( results )
        merged = {
            map:              [],
            total:            0,
            safe:             0,
            unsafe:           0,
            issue_percentage: 0
        }

        results.each do |healthmap|
            merged[:map]    |= healthmap[:map]
            merged[:total]  += healthmap[:total]
            merged[:safe]   += healthmap[:safe]
            merged[:unsafe] += healthmap[:unsafe]
        end
        merged[:issue_percentage] = ( ( merged[:unsafe].to_f / merged[:total].to_f ) * 100 ).round
        merged
    end


    def self.info
        {
            name:        'Health map',
            description: %q{Generates a simple list of safe/unsafe URLs.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.3'
        }
    end

end
