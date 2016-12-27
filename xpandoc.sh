#!/bin/bash
#
# powerful pandoc markdown converter (markdown ==> html, pdf)
#
# Author: OuyangXY <hh123okbb@gmail.com>
#         pax <coolwinding@gmail.com>

usage() {
	cat <<EOF
Usage: xpandoc [options] [markdown_files]...
  OPTIONS:
      -c CORE_CSS               core css file path
      -s SIDEBAR_CSS            sidebar css file path
      -a ACCON_CSS              accondion css file path
      -t toc style              0: no toc, 1: regular toc, 2: sidebar toc (default)
      -p                        pure html without any css
      -n                        output html without number sections

  By default, xpandoc converts pandoc's markdown files to
  html and pdf files embedded a sidebar.
EOF
	exit 1
}

# custom for TP-LINK release
CORE_CSS=~/.pandoc/css/t.css
SIDEBAR_CSS=~/.pandoc/css/t_sidebar.css
ACCON_CSS=~/.pandoc/css/t_accondion.css
TEMPLATE=t.html

TOC=--toc
TOC_STYLE=2
NUMBER_SECTIONS=--number-sections

while getopts ":c:s:a:t:pn" OPTION
do
	case $OPTION in
	c ) CORE_CSS="$OPTARG";;
	s ) SIDEBAR_CSS="$OPTARG";;
	a ) ACCON_CSS="$OPTARG";;
	t ) TOC_STYLE="$OPTARG";;
	p ) CORE_CSS="" && SIDEBAR_CSS="";;
	n ) NUMBER_SECTIONS="";;
	* ) usage
	esac
done

if [[ -z "$CORE_CSS" ]]; then
	CSS_C=""
else
	CSS_C="-c "$CORE_CSS""
fi

if [[ -z "$SIDEBAR_CSS" ]]; then
	CSS_S=""
else
	CSS_S="-c "$SIDEBAR_CSS""
fi

if [[ -z "$ACCON_CSS" ]]; then
	CSS_A=""
else
	CSS_A="-c "$ACCON_CSS""
fi

if [[ $TOC_STYLE -eq 0 ]]; then
	TOC=""
	CSS_S=""
elif [[ $TOC_STYLE -eq 1 ]]; then
	CSS_S=""
fi

shift $(( $OPTIND - 1 ))
[ -z "$1" ] && echo "*** need markdown files" && usage

for arg in "$@"; do
	echo "### converting "$arg""
	echo ""
	name=${arg%.*}

	# convert to html
	# cmd: pandoc xxx -t html -o xxx.html
	echo "pandoc \
-f markdown+ignore_line_breaks \
-t html "$arg" -o "$name".html \
"$CSS_C" \
"$CSS_S" \
"$CSS_A" \
"$TOC" \
--template="$TEMPLATE" \
"$NUMBER_SECTIONS" \
--highlight-style=haddock \
--self-contained" | tee /tmp/xpandoc.cmd && sh < /tmp/xpandoc.cmd

	rm -f /tmp/xpandoc.cmd
	if [[ "$?" -eq 0 ]]; then
		echo ">>> output: create "$name".html"
	else
		echo ">>> output: create "$name".html failed!"
		exit 1
	fi
	echo ""

	if [[ -f /usr/bin/wkhtmltopdf ]]; then
		# convert to pdf (via wkhtmltopdf or wkhtmltox if installed)
		# cmd: wkhtmltopdf xxx.html xxx.pdf
		echo "wkhtmltopdf --page-size A4 -T 15 -R 15 -B 15 -L 15 "$name".html "$name".pdf" | tee /tmp/xpandoc.cmd && sh < /tmp/xpandoc.cmd

		rm -f /tmp/xpandoc.cmd
		if [ "$?" -eq 0 ]; then
			echo ">>> output: create "$name".pdf"
		else
			echo ">>> output: create "$name".pdf failed!"
			exit 1
		fi
		echo ""
	else
		#echo "*** dependence: wkhtmltopdf not installed!"
		if [[ -f /usr/bin/latex ]]; then
			# convert to pdf (via LaTeX if installed)
			# cmd: pandoc xxx -t latex -o xxx.pdf
			echo "pandoc -t latex "$name".html -o "$name".pdf" | tee /tmp/xpandoc.cmd && sh < /tmp/xpandoc.cmd

			rm -f /tmp/xpandoc.cmd
			if [ "$?" -eq 0 ]; then
				echo ">>> output: create "$name".pdf"
			else
				echo ">>> output: create "$name".pdf failed!"
				exit 1
			fi
			echo ""
		else
			#echo "*** dependence: latex not installed!"
			echo "*** dependence: install wkhtmltopdf or latex to support convert to PDF."
		fi
	fi

done
