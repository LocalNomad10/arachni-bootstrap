require 'yaml'
require 'sinatra'
set :logging, false

get '/' do
    params.to_s
end

get '/submit' do
    params.to_hash.to_yaml
end

get '/sleep' do
    sleep 2
    <<-EOHTML
    <a href='?input=blah'>Inject here</a>
    #{params[:input]}
    EOHTML
end

get '/refreshable' do
    <<HTML
    <a href="/refreshable?param_name=stuff">Irrelevant</a>
    <a href="/link?param_name=stuff&nonce=#{rand(999)}">Refreshable</a>
HTML
end
