task :default => :push do
end

desc "Push ebook into source control"
task :push, [:commit_message] => [:generate_formats] do | t, args |
  sh 'unzip "Test-Driven Development - Extensive Tutorial.epub"'
  #sh 'git add *'
  sh 'git add ./OEBPS'
  sh "git commit -a -m \"#{args[:commit_message]}\""
  sh 'git push -u origin master'
  sh 'rm -r ./OEBPS'
end

desc "Generate all ebook formats"
multitask :generate_formats => [:epub, :mobi, :pdf, :azw3] do
end

desc "Generate epub format"
task :epub do
  sh 'cp ./Test-Driven\ Development\ -\ Extensive\ Tutorial.epub /home/astral/Dropbox/Public/'
end

desc "Generate older Kindle format"
task :mobi do
  sh 'ebook-convert ./Test-Driven\ Development\ -\ Extensive\ Tutorial.epub .mobi'
  sh 'cp ./Test-Driven\ Development\ -\ Extensive\ Tutorial.mobi /home/astral/Dropbox/Public/'
end

desc "Generate PDF format"
task :pdf do
  sh 'ebook-convert ./Test-Driven\ Development\ -\ Extensive\ Tutorial.epub .pdf --pdf-add-toc --toc-title "Table of Contents" --margin-bottom 20 --margin-top 20 --margin-left 20 --margin-right 20 --pdf-add-toc --change-justification justify'
  sh 'cp ./Test-Driven\ Development\ -\ Extensive\ Tutorial.pdf /home/astral/Dropbox/Public/'
end

desc "Generate newer Kindle format"
task :azw3 do
  sh 'ebook-convert ./Test-Driven\ Development\ -\ Extensive\ Tutorial.epub .azw3'
  sh 'cp ./Test-Driven\ Development\ -\ Extensive\ Tutorial.azw3 /home/astral/Dropbox/Public/'
end

