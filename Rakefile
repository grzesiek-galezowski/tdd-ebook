$LOAD_PATH.unshift File.dirname(__FILE__)

require 'pathname'
require 'shellwords'

$ROOT = Pathname.pwd
$MANUSCRIPT_DIR = $ROOT + "manuscript"

task :default => [:validate_whitespaces, :validate_encoding] do
end

task :validate_whitespaces do
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
	
	  if File.read(rooted_filename).include?("\u00A0")
      raise "File #{rooted_filename} constains an unbreakable space. This will not render correctly on PDF"
	  end 
	  
  end
end

task :validate_encoding do
	puts "lol2"
end

