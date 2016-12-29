#!/usr/bin/env ruby

require 'json'
require 'uri'
require 'digest'
require 'yaml'
require 'yaml/store'

config = YAML.load_file('config.yml')

PASTEC_INDEX_PATH = config[:pastec_index_path]
PASTEC_SERVER = config[:pastec_server]
MAXIMUM_RESOLUTION = 1000
DEFAULT_EXTENSION = 'jpg'
DEFAULT_DELAY = 1

store = YAML::Store.new(config[:persistent_store])

iiif_manifest = JSON.parse(ARGF.read)

manifest_id = Digest::SHA256.hexdigest(iiif_manifest.to_s).to_s
begin
   manifest_id = " #{iiif_manifest['metadata'].select{|m| m['label'] == 'Id'}.first['value']}"
rescue
end

`curl -X POST -d '{"type":"LOAD", "index_path":"#{PASTEC_INDEX_PATH}"' #{PASTEC_SERVER}/index/io`

pastec_identifier = nil
store.transaction do
  pastec_identifier = store[:last_pastec_identifier] || 1
  store[:indexed_files] ||= []
  store[:identifier_mapping] ||= {}
end

metadata_prefix = "#{iiif_manifest['label']}#{manifest_id}".gsub(/[^-.a-zA-Z0-9_]/,'_')
current_sequence = 0
iiif_manifest['sequences'].each do |sequence|
  $stderr.puts "Downloading #{sequence['canvases'].length} canvases"
  current_canvas = 0
  sequence['canvases'].each do |canvas|
    $stderr.puts canvas['label']
    current_image = 0
    canvas['images'].each do |image|
      # $stderr.puts "#{image['resource']['width']} x #{image['resource']['height']}"
      quality = image['resource']['service']['@context'] =~ /iiif.io\/api\/image\/2/ ? 'default' : 'native'
      identifier = image['resource']['service']['@id'].chomp('/')
      url = URI.escape("#{identifier}/full/!#{MAXIMUM_RESOLUTION},#{MAXIMUM_RESOLUTION}/0/#{quality}.#{DEFAULT_EXTENSION}")
      output_filename = File.join('images',[metadata_prefix, current_sequence, current_canvas, canvas['label'], current_image].join('_') + '.' + DEFAULT_EXTENSION)
      $stderr.puts output_filename
      unless File.exist?(output_filename)
        # `curl #{url} | curl -X PUT --data-binary @- #{PASTEC_SERVER}/index/images/#{pastec_identifier}`
        $stderr.puts url
        $stderr.puts `curl -o #{output_filename} #{url}`
        sleep(DEFAULT_DELAY)
      end
      store.transaction do
        unless store[:indexed_files].include?(output_filename)
          unless system("curl -X PUT --data-binary @#{output_filename} #{PASTEC_SERVER}/index/images/#{pastec_identifier}")
            puts $?.inspect
          end
          store[:indexed_files] << output_filename
          store[:identifier_mapping][pastec_identifier] = identifier
          pastec_identifier += 1
        end
      end
      current_image += 1
    end
    current_canvas += 1
  end
  current_sequence += 1
end

store.transaction do
  store[:last_pastec_identifier] = pastec_identifier
end

`curl -X POST -d '{"type":"WRITE", "index_path":"#{PASTEC_INDEX_PATH}"' #{PASTEC_SERVER}/index/io`
