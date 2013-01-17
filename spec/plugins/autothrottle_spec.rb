require_relative '../spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    before( :all ) { run }

    def url
        @url ||= server_url_for( name_from_filename ) + '/'
    end

    context 'when the server response times are' do
        context "bellow threshold" do
            it 'should not affect the max concurrency' do
                pre = http.max_concurrency

                http.max_concurrency.times { http.get( url ) }
                http.run

                http.max_concurrency.should == pre
            end
        end
        context "above threshold" do
            it 'should reduce the max concurrency' do
                pre = http.max_concurrency

                http.max_concurrency.times { http.get( url + 'slow' ) }
                http.run

                http.max_concurrency.should < pre
            end
            context "and then fall bellow threshold" do
                it 'should increase the max concurrency (without exceeding http_req_limit)' do
                    pre = http.max_concurrency

                    (10 * http.max_concurrency).times { http.get( url ) }
                    http.run

                    http.max_concurrency.should > pre
                    http.max_concurrency.should <= options.http_req_limit
                end
            end
        end
    end
end
