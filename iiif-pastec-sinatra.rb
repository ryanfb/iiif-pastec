#!/usr/bin/env ruby

require 'sinatra'
require 'tempfile'
require 'json'
require 'yaml'
require 'yaml/store'
require 'base64'

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
  @query_image = Base64.encode64(File.binread(params['imfile'][:tempfile].path))
  @images = []
  store.transaction do
    parsed_response['image_ids'].each do |image_id|
      @images << {:iiif_identifier => store[:identifier_mapping][image_id], :metadata => store[:metadata_mapping][store[:identifier_mapping][image_id]]}
    end
  end
  haml :post_upload
end
