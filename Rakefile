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

$ROOT = Pathname.pwd
$MANUSCRIPT_DIR = $ROOT + "manuscript"

def for_each_manuscript_file
  errors = DetectedErrors.new
  Dir.foreach($MANUSCRIPT_DIR) do |filename|
    rooted_filename = $MANUSCRIPT_DIR + filename
    
    if filename == '.' or filename == '..'
      puts "skipping #{rooted_filename} - one of . or .."
      next
    end

    if not File.file?(rooted_filename)
      puts "skipping #{rooted_filename} - not a file"
      next
    end
    
    puts "Processing #{rooted_filename}"
	  yield rooted_filename, errors  
  
  end
  errors.assert_none

end

def extract_all_uris_from(filename)
  URI.extract(File.read(filename), /http(s)?|mailto/).map { |el| el.gsub(/[.),:]+$/, '') }
end

class DetectedErrors
  def initialize
    @errors = []
  end
  
  def add(message)
    @errors.push message
  end 
  
  def assert_none
    if not @errors.any?
      puts "no errors detected".green
    else
      puts @errors.each { |err| puts err.red }
      puts "#{@errors.length} errors detected".red
      raise "build failed"
    end
  end
end

task :default => [:validate_encoding, :validate_sample, :detect_dead_links] do
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
    errors.add "#{book_path} and #{sample_path} files are not the same..."
  end 
end

task :detect_dead_links do
  
  puts "Validating links"
  puts "================"

  for_each_manuscript_file do |rooted_filename, errors|
    uris = extract_all_uris_from rooted_filename
    
    uris.each do | uri |
      begin
        url = URI.parse(uri)
        req = Net::HTTP.new(url.host, url.port)
        
        if url.scheme == "https" then 
          req.use_ssl = true
          req.verify_mode = OpenSSL::SSL::VERIFY_NONE # read into this
        end
        
        res = req.request_head(url.path)
        
        message = "#{uri} => #{res.code}, #{res.message}"
        if res.code.to_i == 400 then 
          puts message.yellow
        elsif res.code.to_i > 400 then
          raise message
        else
          puts message.green
        end
        
      rescue Exception => e
        errors.add "Error while checking #{uri}: #{e}"
      end
    end
  end
end

#TODO
#2. refactor
#4. check whether images are up to date
#5. check whether sample.txt is up to date
