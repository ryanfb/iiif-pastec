#!/usr/bin/env ruby

require 'sinatra'
require 'tempfile'
require 'json'
require 'yaml'
require 'yaml/store'

config = YAML.load_file('config.yml')
store = YAML::Store.new(config[:persistent_store])

$stderr.puts config.inspect

get '/' do
  haml :upload
end

post '/upload' do
  $stderr.puts params['imfile'].inspect
  response = `curl -s -X POST --data-binary @#{params['imfile'][:tempfile].path} #{config[:pastec_server]}/index/searcher`.chomp
  $stderr.puts response
  parsed_response = JSON.parse(response)
  images = []
  store.transaction do
    parsed_response['image_ids'].each do |image_id|
      images << store[:identifier_mapping][image_id]
    end
  end
  images.join("\n")
end
