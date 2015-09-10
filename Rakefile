$LOAD_PATH.unshift File.dirname(__FILE__)

require 'pathname'
require 'shellwords'

$ROOT = Pathname.pwd
$MANUSCRIPT_DIR = $ROOT + "manuscript"

task :default => [:validate_whitespaces, :validate_encoding] do
end

task :validate_whitespaces do
  Dir.foreach($MANUSCRIPT_DIR) do |filename|
    next if filename == '.' or filename == '..'
	
	if File.read(filename).include?("\u00A0")
      raise "File #{filename} constains an unbreakable space. This will not render correctly on PDF"
	end 
	  
  end
end

task :validate_encoding do
	puts "lol2"
end

