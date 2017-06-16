#!/bin/bash

P=`dirname $(readlink -f $0)`

# Dependences
{
sudo apt-get install libc6 libffi6 libgmp10 libicu52 liblua5.1-0 libpcre3 libyaml-0-2 zlib1g pandoc pandoc-data

# Support converting to PDF via
# wkhtmltopdf (the newest wkhtmltopdf with patched qt (wkhtmltox) is recommended)
#   Refer to http://wkhtmltopdf.org/ for newest version.
sudo apt-get install wkhtmltopdf
# or LaTeX (included in TeX Live, which has very big, big size...) and xelatex (symlink of xetex)
#sudo apt-get install texlive texlive-xetex
} || {
echo ">>> Install dependent packages failed!"
exit
}

mkdir -p ~/bin ~/.pandoc
ln -fs $P/xpandoc.sh ~/bin/xpandoc.sh
rm -f ~/.pandoc/css ~/.pandoc/templates
ln -s $P/css ~/.pandoc/css
ln -s $P/templates ~/.pandoc/templates
