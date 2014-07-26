filename = "all"

def all_chapters_string
	all_chapters = ""

	File.open "./Book.txt" do |f|
	  f.lines do |line|
		all_chapters += "./" + line.gsub("\n", "") + " "
	  end
	end
end

puts `pandoc --epub-stylesheet=./Stylesheets/Global.css --toc --smart -t epub #{all_chapters_string} --epub-cover-image="./Images/cover.png"  -o #{filename}.epub`
puts `pandoc --toc --standalone --highlight-style=kate --smart -t html #{all_chapters_string} --css="./Stylesheets/Global.css" -o #{filename}.html`
puts `pandoc --toc --smart -t odt #{all_chapters_string} --css="./Stylesheets/Global.css" -o #{filename}.odt`
