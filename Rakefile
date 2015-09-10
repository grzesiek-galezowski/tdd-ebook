$LOAD_PATH.unshift File.dirname(__FILE__)

require 'pathname'
require 'shellwords'
require 'rubygems'
require 'rchardet'

$ROOT = Pathname.pwd
$MANUSCRIPT_DIR = $ROOT + "manuscript"

class DetectedErrors
  def initialize
    @errors = []
  end
  
  def add(message)
    @errors.push message
  end 
  
  def assert_none
    if not @errors.any?
      puts "no errors detected"
    else
      puts @errors.each { |err| puts err }
      puts "#{@errors.length} errors detected"
      raise "build failed"
    end
  end
end

def error_message(rooted_filename, line)
  "File #{rooted_filename} constains an unbreakable space. This will not render correctly on PDF. Line: #{line.gsub("\u00A0", "<!!!!!!!!>")}"
end

task :default => [:validate_whitespaces, :validate_encoding] do
end

task :validate_whitespaces do
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
	  encoding = CharDet.detect(File.read(rooted_filename, :encoding => 'utf-8'))["encoding"]
  
    if encoding != "utf-8"
      errors.add "file #{rooted_filename} has encoding #{encoding}"
    end  
  
    #
    #File.open(rooted_filename, :encoding => 'utf-8') do |f|
      
      #f.each_line do |line|
        #if line.include?("\u00A0")
        #  errors.add error_message(rooted_filename, line)
        #end
      #end
    #end
  end
  errors.assert_none
end

task :validate_encoding do
	puts "lol2"
end



#TODO
#1. aggregate errors
#2. refactor
#3. check files encoding
#4. check whether images are up to date
#5. check whether sample.txt is up to date