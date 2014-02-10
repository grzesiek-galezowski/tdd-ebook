$LOAD_PATH.unshift File.dirname(__FILE__)
require 'custom_commands'

desc "Push ebook into source control"
multitask :push, [:commit_message] => [:unzip_epub, :generate_formats] do | t, args |
  git = Git.new(".")
  git.add_all
  git.add "./OEBPS"
  git.commit_all args[:commit_message]
  git.push_changes_to_master
  sh 'rm -r ./OEBPS'
end

desc "Unzip the source epub file structure"
task :unzip_epub do
  unzip! SOURCE_DOCUMENT
end

desc "Generate all ebook formats"
multitask :generate_formats => [:epub, :mobi, :pdf, :azw3, :htmlz] do
end

desc "Generate epub format"
task :epub do
  copy SOURCE_DOCUMENT, PUBLISH_FOLDER
end

desc "Generate older Kindle format"
task :mobi do
  convert SOURCE_DOCUMENT, to: :mobi
  copy local_ebook_variant(:mobi), PUBLISH_FOLDER
end

desc "Generate PDF format"
task :pdf do
  convert SOURCE_DOCUMENT, to: :pdf, using: PDF_CONVERSION_OPTIONS
  copy local_ebook_variant(:pdf), PUBLISH_FOLDER
end

desc "Generate newer Kindle format"
task :azw3 do
  convert SOURCE_DOCUMENT, to: :azw3
  copy local_ebook_variant(:azw3), PUBLISH_FOLDER
end

desc "Generate HTMLZ format to gh-pages branch directory"
task :htmlz, [:commit_message] do | t, args |
  commit_message = args[:commit_message] || "updated version"
  convert SOURCE_DOCUMENT, to: :htmlz
  copy local_ebook_variant(:htmlz), "../Pages_TDDEbook/tdd-ebook/book.htmlz"
  unzip! "../Pages_TDDEbook/tdd-ebook/book.htmlz", "../Pages_TDDEbook/tdd-ebook/"
  rm "../Pages_TDDEbook/tdd-ebook/book.htmlz"
  git = Git.new "../Pages_TDDEbook/tdd-ebook/"
  git.add_all
  git.commit_all args[:commit_message]
  git.push_changes
end



