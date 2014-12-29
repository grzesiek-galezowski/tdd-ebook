require 'pathname'
require 'shellwords'
require 'rake'

Dir.glob("./*.rb") do |my_text_file|
  if( my_text_file != __FILE__ && my_text_file != "./Config.rb")
    puts "working on: #{my_text_file}..."
    `ruby #{my_text_file}`
  end
end

def to_png(filename, options)
  svg = Pathname.new filename
  png = svg.sub_ext ".png"
  density = options[:density]
  puts sh("inkscape -z -e #{png} -d #{density} ./#{svg}")
end


to_png "RedGreenRefactor.svg", :density => 150
to_png "RedGreenRefactor2.svg", :density => 150
to_png "SenderRecipientMessage.svg", :density => 150
to_png "WebOfObjects.svg", :density => 95

puts sh "java -jar ../tools/plantuml.jar -tsvg ./lollipop.uml"
to_png "lollipop.svg", :density => 150

#this will overwrite the old picture. For now, I am leaving the code that produces the old one
#to be able to safely revert in the future. In long term, the old graphviz-based picture will b retired
puts sh "dpic -v ./SenderRecipientMessage.pic > ./SenderRecipientMessage.svg"
to_png "SenderRecipientMessage.svg", :density => 150

#Pathname.glob("./*.svg") do |svg_image|
#  png_image = svg_image.sub_ext ".png"
#  puts sh("inkscape -z -e #{png_image} -h 600 -w 480 ./#{svg_image}")
#end