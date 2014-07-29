$LOAD_PATH.unshift File.dirname(__FILE__)
require 'custom_commands'

task :default => :push do
end

desc "Push all deliverables into source control"
task :push, [:commit_message] => [:push_ebook, :push_html] do | t, args |
end


desc "Push ebook into source control"
task :push_ebook, [:commit_message] => ['formats:all', 'dropbox_deployment:all'] do | t, args |
  #TODO repair this
  remove_pandoc_manuscript
  git = Git.new $ROOT
  git.pull
  git.add_all
  git.commit_all args[:commit_message]
  git.push_changes_to_master
end

namespace :dropbox_deployment do

  desc 'publish all items in dropbox folder'
  multitask :all => ['dropbox_deployment:epub', 'dropbox_deployment:mobi', 'dropbox_deployment:azw3', 'dropbox_deployment:pdf']

  desc 'puts epub version in dropbox folder'
  task :epub => 'formats:epub' do
    copy SOURCE_DOCUMENT, PUBLISH_FOLDER
  end

  desc 'puts mobi version in dropbox folder'
  task :mobi => 'formats:mobi' do
    copy local_ebook_variant(:mobi), PUBLISH_FOLDER
  end

  desc 'puts azw3 version in dropbox folder'
  task :azw3 => 'formats:azw3' do
    copy local_ebook_variant(:azw3), PUBLISH_FOLDER
  end

  desc 'puts pdf version in dropbox folder'
  task :pdf => 'formats:pdf' do
    copy local_ebook_variant(:pdf), PUBLISH_FOLDER
  end
end

desc "Commit HTML version to github pages"
task :push_html, [:commit_message] => 'formats:html' do | t, args |
  git = Git.new $PAGES_PATH
  git.pull
  git.add_all
  git.commit_all args[:commit_message]
  git.push_changes_to_gh_pages
end

namespace :diagrams do
  #not diagrams, but images!!! 
  desc "Regenerates all SVG diagrams from source and puts them in the source directory"
  task :regenerate do
    puts sh("cd ./Diagrams/ && ruby ./Generate.rb")
    puts move(Dir.glob('./Diagrams/*.svg'), $MANUSCRIPT_IMAGES_DIR, :verbose => true)
    puts move(Dir.glob('./Diagrams/*.png'), $MANUSCRIPT_IMAGES_DIR, :verbose => true)
  end
end

task :clone_manuscript => 'diagrams:regenerate' do 
  remove_pandoc_manuscript
  cp_r $MANUSCRIPT_DIR, $PD_MANUSCRIPT_DIR
  
  # remove leanpub code language markers
  puts sh("cd #{$PD_MANUSCRIPT_DIR.to_s.shellescape} && sed -ri '/\\{lang=/d' *.txt")
  # replace leanpub parts with chapters
  puts sh("cd #{$PD_MANUSCRIPT_DIR.to_s.shellescape} && sed -ri 's/^-# /# /' *.txt")
end

namespace :formats do
  desc "Generate all ebook formats"
  task :all => ['formats:pandoc', 'formats:calibre'] do
  end

  desc "Generate formats using pandoc"
  multitask :pandoc => ['formats:epub', 'formats:html']

  desc "Generate formats using Calibre's ebook-convert tool"
  task :calibre => ['formats:mobi', 'formats:pdf', 'formats:azw3']

  desc "Generate epub format"
  task :epub => :clone_manuscript do
    copy $PD_MANUSCRIPT_GLOBAL_STYLESHEET, $EPUB_DEFAULT_STYLESHEET
    generate_epub $PD_MANUSCRIPT_DIR, local_ebook_variant(:epub)
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
  task :html => :clone_manuscript do | t, args |
    generate_html $PD_MANUSCRIPT_DIR, $HTML_INDEX
    move $ROOT + $HTML_INDEX, $PAGES_PATH
    cp_r $PD_MANUSCRIPT_IMAGES_DIR, $PAGES_PATH
    cp_r $PD_MANUSCRIPT_STYLESHEETS_DIR, $PAGES_PATH
    cp_r $ROOT_DIR_COVER_IMAGE, $PAGES_IMAGES_PATH
  end

  desc "Generate PDF format"
  task :alt_pdf => :clone_manuscript do
    generate_pdf $PD_MANUSCRIPT_DIR, local_ebook_variant(:pdf)
  end

  desc "Generate ODT format"
  task :odt => :clone_manuscript do
    generate_pdf $PD_MANUSCRIPT_DIR, local_ebook_variant(:odt)
  end
end

def remove_pandoc_manuscript
  rm_rf($PD_MANUSCRIPT_DIR) if $PD_MANUSCRIPT_DIR.exist?
end

