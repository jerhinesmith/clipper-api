require 'sinatra'
require 'yajl/json_gem'
require 'sea_witch'

before do
  @client = SeaWitch::Client.new(params[:username], params[:password])
end

get '/balance' do
  content_type :json

  { username: @client.username, balance: @client.balance }.to_json
end