$LOAD_PATH.unshift File.dirname(__FILE__)

require 'pathname'
require 'shellwords'

$ROOT = Pathname.pwd
$MANUSCRIPT_DIR = $ROOT + "manuscript"

task :default => [:validate_whitespaces, :validate_encoding] do
end

task :validate_whitespaces do
  Dir.foreach($MANUSCRIPT_DIR) do |filename|
    if filename == '.' or filename == '..'
      puts "skipping #{filename} - one of . or .."
      next
    end

    if not File.file?(filename)
      puts "skipping #{filename} - not a file"
      next
    end
    
    puts "Processing #{filename}"
	
	  if File.read(filename).include?("\u00A0")
      raise "File #{filename} constains an unbreakable space. This will not render correctly on PDF"
	  end 
	  
  end
end

task :validate_encoding do
	puts "lol2"
end

