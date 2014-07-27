require 'pathname'
require 'shellwords'
require 'tmpdir'

def local_ebook_variant(extension)
  "./Test-Driven Development - Extensive Tutorial.#{extension}"
end

$ROOT = Pathname.pwd
$USER_HOME = Pathname.new Dir.home

#leanpub manuscript paths
$MANUSCRIPT_DIR = $ROOT + "manuscript"
$MANUSCRIPT_IMAGES_DIR = $MANUSCRIPT_DIR + "images"
$MANUSCRIPT_COVER_IMAGE = $MANUSCRIPT_IMAGES_DIR + "title_page.png"
$MANUSCRIPT_STYLESHEETS_DIR = $MANUSCRIPT_DIR + "Stylesheets"
$MANUSCRIPT_GLOBAL_STYLESHEET = $MANUSCRIPT_STYLESHEETS_DIR + "Global.css"

#pandoc paths
$PD_MANUSCRIPT_DIR = $ROOT + "manuscript"
$PD_MANUSCRIPT_IMAGES_DIR = $PD_MANUSCRIPT_DIR + "images"
$PD_MANUSCRIPT_COVER_IMAGE = $PD_MANUSCRIPT_IMAGES_DIR + "title_page.png"
$PD_MANUSCRIPT_STYLESHEETS_DIR = $PD_MANUSCRIPT_DIR + "Stylesheets"
$PD_MANUSCRIPT_GLOBAL_STYLESHEET = $PD_MANUSCRIPT_STYLESHEETS_DIR + "Global.css"

$EPUB_DEFAULT_STYLESHEET = Pathname.new(Dir.home) + ".pandoc"

#HTML paths
$PAGES_PATH = $ROOT + "../Pages_TDDEbook/tdd-ebook"
$PAGES_IMAGES_PATH = $PAGES_PATH + "images"
$HTML_INDEX = "index.html"

$ROOT_DIR_COVER_IMAGE = $ROOT + "cover_real.png"

SOURCE_DOCUMENT = local_ebook_variant(:epub)
PUBLISH_FOLDER = $USER_HOME + 'Dropbox/Public/'
PDF_CONVERSION_OPTIONS = "--margin-bottom 20 --margin-top 20 --margin-left 20 --margin-right 20 --change-justification justify"

PUBLISH_FOLDER.mkpath unless PUBLISH_FOLDER.exist? and PUBLISH_FOLDER.readable?

class String
  def without_endline
    gsub("\n", "")
  end
end

#def unzip!(archive, exdir = nil)
#  exdir ||= "."
#  exdir = File.expand_path exdir.shellescape
#  exdir = exdir.shellescape
#  temp_directory = "______temp_unzip___"  
#  archive = File.expand_path archive
#  archive = archive.shellescape
#
#  Dir.mktmpdir("____tdd_ebook_unzip____") do |temp_dir|
#    temp_dir = temp_dir.shellescape
#    puts sh("unzip -o #{archive} -d #{temp_dir}")
#    sh "rsync -av #{temp_dir}/ #{exdir}"
#  end
#  
#end

def convert(source_ebook, params)
  params[:using] ||= ""
  params[:to] ||= params[:to].to_s.shellescape
  source_ebook = source_ebook.shellescape
  sh "ebook-convert #{source_ebook} .#{params[:to].to_s} #{params[:using]}"
end

def all_chapters_string(subdir)
  all_chapters = String.new

  File.open subdir + "Book.txt" do |f|
    f.lines do |line|
      all_chapters += "./" + line.without_endline + " "
    end
  end
  return all_chapters
end

$common_pandoc_opts = "--toc --toc-depth=2 --smart"
$pandoc_highlight_opts = "--highlight-style=pygments"
$epub_cover_image = "--epub-cover-image=#{$PD_MANUSCRIPT_COVER_IMAGE.to_s.shellescape}"
$epub_stylesheet = "--epub-stylesheet=#{$PD_MANUSCRIPT_GLOBAL_STYLESHEET.to_s.shellescape}"
$global_css = "--css=#{$PD_MANUSCRIPT_GLOBAL_STYLESHEET.to_s.shellescape}"

def generate_epub(subdir, filename)
  options = [
    $epub_stylesheet,
    $epub_cover_image,
    $pandoc_highlight_opts,
    "-t epub"]
  generate_format subdir, filename, options
end

def generate_html(subdir, filename)
  options = [
    $global_css,
    $pandoc_highlight_opts,
    "--standalone",
    "-t html",
    "./Cover.txt"
  ]
  generate_format subdir, filename, options
end

def generate_pdf(subdir, filename)
  options = [
    $global_css,
    $pandoc_highlight_opts,
    "--standalone",
    "--chapters",
    "-t latex"
  ]
  generate_format subdir, filename, options
end

def generate_odt(subdir, filename)
  options = [
    $global_css, 
    $pandoc_highlight_opts, 
    "--standalone", 
    "-t odt"]
  generate_format subdir, filename, options
end

def generate_format(subdir, filename, additional_options)
  filename = filename.shellescape
  cmd_begin = "cd #{subdir.to_s.shellescape} && pandoc #{$common_pandoc_opts} "
  cmd_custom = String.new
  additional_options.each { |opt| cmd_custom = cmd_custom + " " + opt + " " }
  
  cmd_end = "#{all_chapters_string(subdir)} -o ../#{filename}"
  puts sh( cmd_begin + cmd_custom + cmd_end)
end


class Git
  include FileUtils

  def initialize(path_to_repository)
    @path = path_to_repository.to_s.shellescape
  end

  def execute_in_repository_root(command)
    sh "cd #{@path} && #{command}"
  end

  def add_all()
    begin
      execute_in_repository_root "git add --all"
    rescue 
      puts "Nothing to add to source control"
    end
  end

  def add(path)
    execute_in_repository_root "git add --all #{path}"
  end

  def commit_all(commit_message)
    execute_in_repository_root "git commit -a -m \"#{commit_message}\""
  end

  def pull
    execute_in_repository_root "git pull"
  end 

  def push_changes_to_master
    execute_in_repository_root "git push -u origin master"
  end

  def push_changes_to_gh_pages
    execute_in_repository_root "git push -u origin gh-pages"
  end

end

