$LOAD_PATH.unshift File.dirname(__FILE__)
require 'custom_commands'

desc "Push ebook into source control"
task :push, [:commit_message] => [:all_formats, :dropbox_items, :push_html] do | t, args |
  #TODO repair this
  git = Git.new $ROOT
  git.pull
  git.add_all
  git.commit_all args[:commit_message]
  git.push_changes_to_master
end

desc 'publish all items in dropbox folder'
multitask :dropbox_items => [:dropbox_epub, :dropbox_mobi, :dropbox_azw3, :dropbox_pdf]

desc 'puts epub version in dropbox folder'
task :dropbox_epub => :epub do
  copy SOURCE_DOCUMENT, PUBLISH_FOLDER
end

desc 'puts mobi version in dropbox folder'
task :dropbox_mobi => :mobi do
  copy local_ebook_variant(:mobi), PUBLISH_FOLDER
end

desc 'puts azw3 version in dropbox folder'
task :dropbox_azw3 => :azw3 do
  copy local_ebook_variant(:azw3), PUBLISH_FOLDER
end

desc 'puts pdf version in dropbox folder'
task :dropbox_pdf => :pdf do
  copy local_ebook_variant(:pdf), PUBLISH_FOLDER
end

desc "Generate all ebook formats"
task :all_formats => [:pandoc_formats, :calibre_formats] do
end

desc "Generate formats using pandoc"
multitask :pandoc_formats => [:epub, :html]

desc "Generate formats using Calibre's ebook-convert tool"
task :calibre_formats => [:mobi, :pdf, :azw3]

desc "Generate epub format"
task :epub do
  copy $GLOBAL_MANUSCRIPT_STYLESHEET, $EPUB_DEFAULT_STYLESHEET
  generate_epub $MANUSCRIPT_DIR, local_ebook_variant(:epub)
end

desc "Generate older Kindle format"
task :mobi => :epub do
  convert SOURCE_DOCUMENT, to: :mobi
end

desc "Generate PDF format"
task :pdf => :epub do
  convert SOURCE_DOCUMENT, to: :pdf, using: PDF_CONVERSION_OPTIONS
end

desc "Generate newer Kindle format"
task :azw3 => :epub do
  convert SOURCE_DOCUMENT, to: :azw3
end

desc "Generate single-page HTML document to gh-pages branch directory"
task :html do | t, args |
  generate_html $MANUSCRIPT_DIR, $HTML_INDEX
  move $ROOT + $HTML_INDEX, $PAGES_PATH
  cp_r $MANUSCRIPT_IMAGES_DIR, $PAGES_PATH
  cp_r $MANUSCRIPT_STYLESHEETS_DIR, $PAGES_PATH
  cp_r $ROOT_DIR_COVER_IMAGE, $PAGES_IMAGES_PATH
end

desc "Generate PDF format"
task :alt_pdf do
  generate_pdf $MANUSCRIPT_DIR, local_ebook_variant(:pdf)
end

desc "Generate ODT format"
task :odt do
  generate_pdf $MANUSCRIPT_DIR, local_ebook_variant(:odt)
end

desc "Commit HTML version to github pages"
task :push_html, [:commit_message] => :html do | t, args |
  git = Git.new $PAGES_PATH
  git.pull
  git.add_all
  git.commit_all args[:commit_message]
  git.push_changes_to_gh_pages
end

#not diagrams, but images!!! 
desc "Regenerates all SVG diagrams from source and puts them in the source directory"
task :regenerate_diagrams do
  puts sh("cd ./Diagrams/ && ruby ./Generate.rb")
  puts move(Dir.glob('./Diagrams/*.svg'), $MANUSCRIPT_IMAGES_DIR, :verbose => true)
  puts move(Dir.glob('./Diagrams/*.png'), $MANUSCRIPT_IMAGES_DIR, :verbose => true)
end

task :default => :push do
end
