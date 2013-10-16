#!/bin/sh

ebook-convert ./Test-Driven\ Development\ -\ Extensive\ Tutorial.epub .mobi
ebook-convert ./Test-Driven\ Development\ -\ Extensive\ Tutorial.epub .pdf
cp ./Test-Driven\ Development\ -\ Extensive\ Tutorial.mobi /media/astral/Kindle/documents/Test-Driven\ Development\ -\ Extensive\ Tutorial.mobi
unzip "Test-Driven Development - Extensive Tutorial.epub"
git add *
git add ./OEBPS
git commit -a -m "$1"
git push -u origin master
rm -r ./OEBPS
