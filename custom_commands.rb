require 'shellwords'
require 'tmpdir'

def local_ebook_variant(extension)
  "./Test-Driven Development - Extensive Tutorial.#{extension}"
end

def unzip!(archive, exdir = nil)
  exdir ||= "."
  exdir = File.expand_path exdir.shellescape
  exdir = exdir.shellescape
  temp_directory = "______temp_unzip___"  
  archive = File.expand_path archive
  archive = archive.shellescape

  Dir.mktmpdir("____tdd_ebook_unzip____") do |temp_dir|
    temp_dir = temp_dir.shellescape
    puts sh("unzip -o #{archive} -d #{temp_dir}")
    sh "rsync -r #{temp_dir}/* #{exdir}"
  end
  
end

def convert(source_ebook, params)
  params[:using] ||= ""
  params[:to] ||= params[:to].shellescape
  source_ebook = source_ebook.shellescape
  sh "ebook-convert #{source_ebook} .#{params[:to].to_s} #{params[:using]}"
end

SOURCE_DOCUMENT = local_ebook_variant(:epub)
PUBLISH_FOLDER = '/home/astral/Dropbox/Public/'
PDF_CONVERSION_OPTIONS = "--pdf-add-toc --toc-title \"Table of Contents\" --margin-bottom 20 --margin-top 20 --margin-left 20 --margin-right 20 --pdf-add-toc --change-justification justify"

task :default => :push do
end

class Git
  include FileUtils

  def initialize(path_to_repository)
    @path = path_to_repository
  end

  def execute_in_repository_root(command)
    sh "cd \"#{@path}\" && #{command}"
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

