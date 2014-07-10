Dir.glob("./*.rb") do |my_text_file|
  if( my_text_file != __FILE__ && my_text_file != "./Config.rb")
    puts "working on: #{my_text_file}..."
    `ruby #{my_text_file}`
  end
end
