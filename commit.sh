#!/bin/sh

unzip TDD.epub
git add *
git commit -a -m "Further work"
git push -u origin master