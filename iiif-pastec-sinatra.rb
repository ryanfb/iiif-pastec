#!/usr/bin/env ruby

require 'sinatra'
require 'tempfile'

get '/' do
  haml :upload
end

post '/upload' do
  $stderr.puts params['imfile'].inspect
  response = `curl -s -X POST --data-binary @#{params['imfile'][:tempfile].path} http://localhost:4212/index/searcher`
end
