$LOAD_PATH.unshift File.dirname(__FILE__)
require 'custom_commands'

task :default => :push do
end

desc "Push all deliverables into source control"
task :push, [:commit_message] => [:push_ebook, :push_html] do | t, args |
end

desc "Push ebook into source control"
task :push_ebook, [:commit_message] => ['formats:all', 'sample:generate'] do | t, args |
  #TODO repair this
  remove_pandoc_manuscript
  git = Git.new $ROOT
  git.pull
  git.add_all
  git.commit_all args[:commit_message]
  git.push_changes_to_master
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

  # replace leanpub parts with chapters
  replace_in_temp_markdown_files "^-#", "# "
  # replace asides with blocks
  replace_in_temp_markdown_files "^A> ", "> "
  replace_in_temp_markdown_files "^A>$", ">"
  # replace warnings with blocks
  replace_in_temp_markdown_files "^W> ", "> "
  replace_in_temp_markdown_files "^W>$", ">"
  # replace tips with blocks
  replace_in_temp_markdown_files "^T> ", "> "
  replace_in_temp_markdown_files "^T>$", ">"
  # replace errors with blocks
  replace_in_temp_markdown_files "^E> ", "> "
  replace_in_temp_markdown_files "^E>$", ">"
  # replace information with blocks
  replace_in_temp_markdown_files "^I> ", "> "
  replace_in_temp_markdown_files "^I>$", ">"
  # replace questions with blocks
  replace_in_temp_markdown_files "^Q> ", "> "
  replace_in_temp_markdown_files "^Q>$", ">"
  # replace discussions with blocks
  replace_in_temp_markdown_files "^D> ", "> "
  replace_in_temp_markdown_files "^D>$", ">"
  # replace exercises with blocks
  replace_in_temp_markdown_files "^X> ", "> "
  replace_in_temp_markdown_files "^X>$", ">"
  # replace generic blocks with blocks
  replace_in_temp_markdown_files "^G> ", "> "
  replace_in_temp_markdown_files "^G>$", ">"

  #use java source code highlight as pandoc does not support C#
  replace_in_temp_markdown_files "^```csharp", "```java"
end

def replace_in_temp_markdown_files(replaced, replacement)
  puts sh("cd #{$PD_MANUSCRIPT_DIR.to_s.shellescape} && sed -ri 's/#{replaced}/#{replacement}/' *.md")
end

namespace :sample do
  task :generate do
    cp_r $MANUSCRIPT_BOOK_CHAPTERS_LIST, $MANUSCRIPT_SAMPLE_CHAPTERS_LIST
  end
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

