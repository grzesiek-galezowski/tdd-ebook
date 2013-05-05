#!/bin/sh

ebook-convert ./Test-Driven\ Development\ -\ Extensive\ Tutorial.epub .mobi
cp ./Test-Driven\ Development\ -\ Extensive\ Tutorial.mobi /media/astral/Kindle/documents/
unzip "Test-Driven Development - Extensive Tutorial.epub"
git add *
git commit -a -m "$1"
git push -u origin master
rm -r ./OEBPS
