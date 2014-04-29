require 'sinatra'
require 'yajl/json_gem'
require File.join(File.dirname(__FILE__), 'lib', 'clipper', 'lib', 'clipper', 'client')

before do
  @client = Clipper::Client.new(params[:username], params[:password])
end

get '/balance' do
  content_type :json

  { username: @client.username, balance: @client.balance }.to_json
end