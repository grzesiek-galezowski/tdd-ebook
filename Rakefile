require 'shellwords'

def local_ebook_variant(extension)
  "./Test-Driven Development - Extensive Tutorial.#{extension}"
end

def unzip(archive)
  archive = Shellwords.escape(archive)
  sh "unzip #{archive}"
end

def convert(source_ebook, params)
  params[:using] ||= ""
  params[:to] ||= Shellwords.escape(params[:to])
  source_ebook = Shellwords.escape(source_ebook)
  sh "ebook-convert #{source_ebook} .#{params[:to].to_s} #{params[:using]}"
end

SOURCE_DOCUMENT = local_ebook_variant(:epub)
PUBLISH_FOLDER = '/home/astral/Dropbox/Public/'
PDF_CONVERSION_OPTIONS = "--pdf-add-toc --toc-title \"Table of Contents\" --margin-bottom 20 --margin-top 20 --margin-left 20 --margin-right 20 --pdf-add-toc --change-justification justify"

task :default => :push do
end

class Git
  include FileUtils

  def self.execute
    Git.new
  end

  def add_all()
    begin
      sh 'git add *'
    rescue 
      puts "Nothing to add to source control"
    end
  end

  def add(path)
    sh "git add #{path}"
  end

  def commit_all(commit_message)
    sh "git commit -a -m \"#{commit_message}\""
  end
 
  def push_changes_to_master
    sh 'git push -u origin master'
  end
end

desc "Push ebook into source control"
task :push, [:commit_message] => [:unzip_epub, :generate_formats] do | t, args |
  Git.execute.add_all
  Git.execute.add "./OEBPS"
  Git.execute.commit_all args[:commit_message]
  Git.execute.push_changes_to_master
  sh 'rm -r ./OEBPS'
end

task :unzip_epub do
  unzip SOURCE_DOCUMENT
end

desc "Generate all ebook formats"
multitask :generate_formats => [:epub, :mobi, :pdf, :azw3] do
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



