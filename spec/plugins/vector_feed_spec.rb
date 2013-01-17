require_relative '../spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    def url
        'http://test.com/'
    end

    before( :all ) do
        options.url = url
        options.do_not_crawl
    end

    def vectors
        [
            {
                'type' => 'page',
                'url'  => url,
                'code' => 200,
                'headers' => { 'Content-Type '=> "text/html; charset=utf-8" },
                'body' => "HTML code goes here"
            },
            {
                'type'   => 'link',
                'action' => "#{url}link",
                'inputs' => { 'my_param' => 'my val' }
            },
            {
                'type'   => 'form',
                'method' => 'post',
                'action' => "#{url}form",
                'inputs' => {
                    'post_this' => 'HUA!',
                    'csrf'      => "my_csrf_token"
                },
                'skip' => %w(csrf)
            },
            {
                'type'   => 'cookie',
                'action' => "#{url}cookie",
                'inputs' => { 'session_id' => '43434234343sddsdsds' }
            },
            {
                'type'   => 'header',
                'action' => "#{url}header",
                'inputs' => { 'User-Agent' => "Blah/2" }
            }
        ]
    end

    def check( pages )
        v = vectors

        oks = 0
        pages.each do |page|
            if page.response_headers.any?
                page.url.should  == v.first['url']
                page.code.should == v.first['code']
                page.body.should == v.first['body']

                page.response_headers.should == v.first['headers']

                oks += 1
            end

            if page.cookies.any?
                page.cookies.size.should == 1
                cookie = v.select { |vector| vector['type'] == 'cookie' }.first
                page.cookies.first.action.should == cookie['action']
                page.cookies.first.auditable.should == cookie['inputs']

                page.url.should  == cookie['action']
                page.code.should == 200
                page.body.should == ''

                oks += 1
            end

            if page.links.any?
                link = v.select { |vector| vector['type'] == 'link' }.first
                page.links.first.action.should == link['action']
                page.links.first.auditable.should == link['inputs']

                page.url.should  == url
                page.code.should == 200
                page.body.should == ''

                oks += 1
            end

            if page.forms.any?
                form = v.select { |vector| vector['type'] == 'form' }.first
                page.forms.first.action.should == form['action']
                page.forms.first.auditable.should == form['inputs']

                page.forms.first.immutables.include?( form['skip'].first ).should be_true

                page.url.should  == url
                page.code.should == 200
                page.body.should == ''

                oks += 1
            end

            if page.headers.any?
                header = v.select { |vector| vector['type'] == 'header' }.first
                page.headers.first.action.should == header['action']
                page.headers.first.auditable.should == header['inputs']

                page.url.should  == header['action']
                page.code.should == 200
                page.body.should == ''

                oks += 1
            end
        end

        oks.should == 5
    end

    def run_test
        pages = []
        framework.add_on_run_mods { |page| pages << page }
        run

        check( pages )
    end

    context 'when setting the option' do
        describe :vectors do
            it 'should forward the given vectors to the framework to be audited' do
                options.plugins[name_from_filename] = { 'vectors' => vectors.dup }
                run_test
            end
        end

        describe :yaml_string do
            it 'should unserialize the given string and forward the given vectors to the framework to be audited' do
                options.plugins[name_from_filename] = { 'yaml_string' => vectors.to_yaml}
                run_test
            end
        end

        describe :yaml_file do
            it 'should unserialize the given string and forward the given vectors to the framework to be audited' do
                File.open( 'yaml_file.yml', 'w' ){ |f| f.write( YAML.dump( vectors ) ) }
                options.plugins[name_from_filename] = { 'yaml_file' => 'yaml_file.yml' }
                run_test

                File.delete( 'yaml_file.yml' )
            end
        end
    end
end
