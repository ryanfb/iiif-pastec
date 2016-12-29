# iiif-pastec

Scripts for using [Pastec](http://pastec.io/) as an image-based search engine for [IIIF](http://iiif.io/) image servers.

## Requirements

 * Ruby 2+
 * [bundler](http://bundler.io/)
 * curl
 * A running Pastec server

## Usage

Use e.g. `./iiif-pastec-ingest.rb manifest.json` to bounce all images in a IIIF manifest into your Pastec server. Images will be downloaded/cached locally in `images/` to avoid strain on the IIIF server and speed up repeated runs during development/testing.

Then you can run `bundle exec ./iiif-pastec-sinatra.rb` to run a simple Sinatra-based search frontend. You can search by uploading an image in the resulting web form.
