#!/bin/sh

ebook-convert ./TDD.epub ./TDD.mobi
unzip TDD.epub
git add *
git commit -a -m "$1"
git push -u origin master