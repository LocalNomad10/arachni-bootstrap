require 'sinatra'
require 'sinatra/contrib'
set :logging, false

get '/' do
    cookies[:cookie1] = 'foo'
   <<HTML
    <a href='?foo=bar'>Link</a>
    <form>
        <input name='input1' />
    </form>
HTML
end

get '/non_text_content_type' do
    headers 'Content-Type' => "foo"
end

get '/new_form' do
    <<HTML
    <form>
        <input name='input2' />
    </form>
HTML
end

get '/new_link' do
    <<HTML
    <a href='?link_param=bar2'>Link</a>
HTML
end

get '/new_cookie' do
    cookies[:new_cookie] = 'hua!'
    ''
end

get '/redirect' do
    ''
end
