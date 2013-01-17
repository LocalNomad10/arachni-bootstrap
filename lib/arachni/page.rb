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

module Arachni

#
# It holds page data like elements, cookies, headers, etc...
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
#
class Page

    #
    # @return    [String]    url of the page
    #
    attr_reader :url

    #
    # @return    [Fixnum]    the HTTP response code
    #
    attr_reader :code

    #
    # @return    [String]    the request method that returned the page
    #
    attr_reader :method

    #
    # @return    [Hash]    url variables
    #
    attr_reader :query_vars

    #
    # @return    [String]    the HTML response
    #
    attr_reader :body

    #
    # Request headers
    #
    # @return    [Array<Element::Header>]
    #
    attr_reader :headers

    #
    # @return    [Hash]
    #
    attr_reader :request_headers

    #
    # @return    [Hash]
    #
    attr_reader :response_headers

    # @return    [Array<String>]
    attr_reader :paths

    #
    # @see Parser#links
    #
    # @return    [Array<Element::Link>]
    #
    attr_accessor :links

    #
    # @see Parser#forms
    #
    # @return    [Array<Element::Form>]
    #
    attr_accessor :forms

    #
    # @see Parser#cookies
    #
    # @return    [Array<Element::Cookie>]
    #
    attr_accessor :cookies

    #
    # Cookies extracted from the supplied cookiejar
    #
    # @return    [Array<Element::Cookie>]
    #
    attr_accessor :cookiejar

    def self.from_url( url, opts = {}, &block )
        responses = []

        opts[:precision] ||= 1
        opts[:precision].times {
            HTTP.get( url, opts[:http] || {} ) do |res|
                responses << res
                next if responses.size != opts[:precision]
                block.call( from_response( responses ) ) if block_given?
            end
        }

        if !block_given?
            HTTP.run
            from_response( responses )
        end
    end

    def self.from_response( res, opts = Options )
        Parser.new( res, opts ).page
    end
    class << self; alias :from_http_response :from_response end

    def initialize( opts = {} )
        opts.each { |k, v| instance_variable_set( "@#{k}".to_sym, try_dup( v ) ) }

        @forms ||= []
        @links ||= []
        @cookies ||= []
        @headers ||= []

        @cookiejar ||= {}
        @paths ||= []

        @response_headers ||= {}
        @request_headers  ||= {}
        @query_vars       ||= {}

        @url    = Utilities.normalize_url( @url )
        @body ||= ''
    end

    def html
        @body
    end

    def document
        @document ||= Nokogiri::HTML( @body )
    end

    def text?
        !!@text
    end

    def title
        document.css( 'title' ).first.text rescue nil
    end

    def to_hash
        instance_variables.reduce({}) do |h, iv|
            if iv != :@document
                h[iv.to_s.gsub( '@', '').to_sym] = try_dup( instance_variable_get( iv ) )
            end
            h
        end
    end

    def hash
        ((links.map { |e| e.hash } + forms.map { |e| e.hash } +
            cookies.map { |e| e.hash } + headers.map { |e| e.hash }).sort.join +
            body.to_s).hash
    end

    def ==( other )
        hash == other.hash
    end

    def eql?( other )
        self == other
    end

    def dup
        self.deep_clone
    end

    private

    def try_dup( v )
        v.dup rescue v
    end

end
end
