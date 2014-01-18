#!/bin/sh

ebook-convert ./Test-Driven\ Development\ -\ Extensive\ Tutorial.epub .mobi
ebook-convert ./Test-Driven\ Development\ -\ Extensive\ Tutorial.epub .pdf --pdf-add-toc --toc-title "Table of Contents" --margin-bottom 20 --margin-top 20 --margin-left 20 --margin-right 20 --pdf-add-toc --change-justification justify
ebook-convert ./Test-Driven\ Development\ -\ Extensive\ Tutorial.epub .azw3
#cp ./Test-Driven\ Development\ -\ Extensive\ Tutorial.mobi /media/astral/Kindle/documents/Test-Driven\ Development\ -\ Extensive\ Tutorial.mobi

cp ./Test-Driven\ Development\ -\ Extensive\ Tutorial.epub /home/astral/Dropbox/Public/
cp ./Test-Driven\ Development\ -\ Extensive\ Tutorial.mobi /home/astral/Dropbox/Public/
cp ./Test-Driven\ Development\ -\ Extensive\ Tutorial.pdf /home/astral/Dropbox/Public/
cp ./Test-Driven\ Development\ -\ Extensive\ Tutorial.azw3 /home/astral/Dropbox/Public/

unzip "Test-Driven Development - Extensive Tutorial.epub"
git add *
git add ./OEBPS
git commit -a -m "$1"
git push -u origin master
rm -r ./OEBPS
