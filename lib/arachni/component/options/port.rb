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

###
#
# Network port option.
#
###
class Arachni::Component::Options::Port < Arachni::Component::Options::Base
    def type
        'port'
    end

    def valid?( value )
        return false if empty_required_value?( value )

        if value && !value.to_s.empty? &&
            ((!value.to_s.match( /^\d+$/ ) || value.to_i <= 0 || value.to_i > 65535))
            return false
        end

        super
    end
end
