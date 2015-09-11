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

task :default => [:validate_encoding] do
end

task :validate_encoding do
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
  
    unless ["UTF-8", "ascii", "utf-8"].include? encoding
      errors.add "file #{rooted_filename} has encoding <#{encoding}>"
    end  
  
  end
  errors.assert_none

end



#TODO
#2. refactor
#4. check whether images are up to date
#5. check whether sample.txt is up to date