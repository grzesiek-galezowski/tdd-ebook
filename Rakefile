$LOAD_PATH.unshift File.dirname(__FILE__)

require 'pathname'
require 'shellwords'
require 'rubygems'
require 'rchardet'
require 'uri'
require "net/http"
require 'colorize'
require "open-uri"
require 'openssl'
require 'differ'
require 'custom_commands_2'

task :default => [:validate_encoding, :validate_sample, :detect_dead_links, "sample:generate"] do
end

task :validate_encoding do

  puts "Validating files encoding"
  puts "========================="
  
  for_each_manuscript_file do |rooted_filename, errors|
      encoding = CharDet.detect(File.read(rooted_filename, :encoding => 'utf-8'))["encoding"]
  
    unless ["UTF-8", "ascii", "utf-8"].include? encoding
      errors.add "file #{rooted_filename} has encoding <#{encoding}>"
    else
      puts "Encoding: #{encoding} - OK".green
    end
      
  end
end

task :validate_sample do
  
  puts "Validating sample file"
  puts "======================"

  book_path = $MANUSCRIPT_DIR + "Book.txt"
  sample_path = $MANUSCRIPT_DIR + "Sample.txt"
  errors = DetectedErrors.new
  
  unless FileUtils.compare_file(book_path, sample_path)
    diff = Differ.diff_by_line File.read(book_path), File.read(sample_path)
    errors.add "#{book_path} and #{sample_path} files are not the same...\n #{diff}"
  end
  errors.assert_none 
end

task :detect_dead_links do
  
  puts "Validating links"
  puts "================"

  for_each_manuscript_file do |rooted_filename, errors|
    uris = extract_all_uris_from rooted_filename
    validate_uris uris, errors
  end
end

namespace :diagrams do
  #not diagrams, but images!!!
  desc "Regenerates all SVG diagrams from source and puts them in the source directory"
  task :regenerate do
    puts sh("cd ./Diagrams/ && ruby ./Generate.rb")
    puts move(Dir.glob('./Diagrams/*.svg'), $MANUSCRIPT_IMAGES_DIR, :verbose => true)
    puts move(Dir.glob('./Diagrams/*.png'), $MANUSCRIPT_IMAGES_DIR, :verbose => true)
  end
end

namespace :sample do
  task :generate do
    cp_r $MANUSCRIPT_BOOK_CHAPTERS_LIST, $MANUSCRIPT_SAMPLE_CHAPTERS_LIST
  end
end


#TODO
#2. refactor
#4. check whether images are up to date
#5. check whether sample.txt is up to date
