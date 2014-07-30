#!/bin/sh
sudo apt-get install \
  ruby \
  rake \
  pandoc \
  ruby-graphviz \
  xdot \
  git \
  default-jdk \
  inkscape \
  ruby-kramdown


sudo -v && wget -nv -O- https://raw.githubusercontent.com/kovidgoyal/calibre/master/setup/linux-installer.py | sudo python -c "import sys; main=lambda:sys.stderr.write('Download failed\n'); exec(sys.stdin.read()); main()"

