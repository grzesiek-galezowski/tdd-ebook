$DEFAULT_FONT_SIZE=11
$SMALL_FONT_SIZE=10

def apply_config_to(graph)
  graph[:fontname] = 'Ubuntu'
  graph[:fontsize] = $DEFAULT_FONT_SIZE
  graph[:overlap] = false
  graph[:splines] = true
end
