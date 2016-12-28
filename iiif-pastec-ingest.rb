#!/usr/bin/env ruby

require 'json'
require 'uri'

PASTEC_SERVER='http://localhost:4212'
MAXIMUM_RESOLUTION=1000
DEFAULT_EXTENSION='jpg'

iiif_manifest = JSON.parse(ARGF.read)

manifest_id = ''
begin
   manifest_id = " #{iiif_manifest['metadata'].select{|m| m['label'] == 'Id'}.first['value']}"
rescue
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
      $stderr.puts "#{image['resource']['width']} x #{image['resource']['height']}"
      quality = image['resource']['service']['@context'] =~ /iiif.io\/api\/image\/2/ ? 'default' : 'native'
      identifier = image['resource']['service']['@id'].chomp('/')
      url = URI.escape("#{identifier}/full/!#{MAXIMUM_RESOLUTION},#{MAXIMUM_RESOLUTION}/0/#{quality}.#{DEFAULT_EXTENSION}")
      $stderr.puts url
    end
  end
end
