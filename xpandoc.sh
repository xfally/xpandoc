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
      -C CORE_CSS               core css file path
      -S SIDEBAR_CSS            sidebar css file path
      -A ACCON_CSS              accondion css file path
      -t toc style              0: no toc, 1: regular toc, 2: sidebar toc (default)
      -p                        pure html without any css
      -n                        output html without number sections
      -s                        output html + javescript slide presentation

  By default, xpandoc converts pandoc's markdown files to
  html and pdf files embedded a sidebar.
EOF
	exit 1
}

# custom for TP-LINK release
CORE_CSS=~/.pandoc/css/t.css
SIDEBAR_CSS=~/.pandoc/css/t_sidebar.css
ACCON_CSS=~/.pandoc/css/t_accondion.css
TEMPLATE="--template=t.html"

TOC="--toc"
TOC_STYLE=2
PURE=0
NUMBER_SECTIONS="--number-sections"
HIGHLIGHT_STYLE="--highlight-style=haddock"
STANDALONE=""
SELF_CONTAINED="--self-contained"
TO="html"
SLIDE_SHOW=0

while getopts ":C:S:A:t:pns" OPTION
do
	case $OPTION in
	C ) CORE_CSS="$OPTARG";;
	S ) SIDEBAR_CSS="$OPTARG";;
	A ) ACCON_CSS="$OPTARG";;
	t ) TOC_STYLE="$OPTARG";;
	p ) PURE=1;;
	n ) NUMBER_SECTIONS="";;
	s ) SLIDE_SHOW=1;;
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

if [[ $TOC_STYLE == 0 ]]; then
	CSS_S=""
	TOC=""
elif [[ $TOC_STYLE == 1 ]]; then
	CSS_S=""
elif [[ $TOC_STYLE == 2 ]]; then
	echo "--toc" > /dev/null
else
	echo "*** arg invalid" && usage
fi

if [[ $PURE == 1 ]]; then
	CSS_C=""
	CSS_S=""
	CSS_A=""
fi

if [[ $SLIDE_SHOW == 1 ]]; then
	TO="slidy"
	CSS_C=""
	CSS_S=""
	CSS_A=""
	TEMPLATE=""
	STANDALONE="-s"
	SELF_CONTAINED=""
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
-t "$TO" \
"$arg" \
-o "$name".html \
"$CSS_C" \
"$CSS_S" \
"$CSS_A" \
"$TOC" \
"$TEMPLATE" \
"$NUMBER_SECTIONS" \
"$HIGHLIGHT_STYLE" \
"$STANDALONE" \
"$SELF_CONTAINED | tee /tmp/xpandoc.cmd && sh < /tmp/xpandoc.cmd

	rm -f /tmp/xpandoc.cmd
	if [[ "$?" == 0 ]]; then
		echo ">>> output: create "$name".html"
	else
		echo ">>> output: create "$name".html failed!"
		exit 1
	fi
	echo ""

	# slide show doesn't need convert to pdf
	if [[ ! $SLIDE_SHOW == 1 ]]; then
		if [[ -f /usr/bin/wkhtmltopdf || /usr/local/bin/wkhtmltopdf ]]; then
			# convert to pdf (via wkhtmltopdf or wkhtmltox if installed)
			# cmd: wkhtmltopdf xxx.html xxx.pdf
			echo "wkhtmltopdf --page-size A4 -T 15 -R 15 -B 15 -L 15 "$name".html "$name".pdf" | tee /tmp/xpandoc.cmd && sh < /tmp/xpandoc.cmd

			rm -f /tmp/xpandoc.cmd
			if [ "$?" == 0 ]; then
				echo ">>> output: create "$name".pdf"
			else
				echo ">>> output: create "$name".pdf failed!"
				exit 1
			fi
			echo ""
		else
			#echo "*** dependence: wkhtmltopdf not installed!"
			if [[ -f /usr/bin/latex && -f /usr/bin/xelatex ]]; then
				# convert to pdf (via LaTeX if installed)
				# cmd: pandoc xxx -t latex -o xxx.pdf
				echo "pandoc -t latex --latex-engine=xelatex -V mainfont=WenQuanYi\ Micro\ Hei\ Mono -V papersize=A4 -V geometry:margin=1.5cm "$name".html -o "$name".pdf" | tee /tmp/xpandoc.cmd && sh < /tmp/xpandoc.cmd

				rm -f /tmp/xpandoc.cmd
				if [ "$?" == 0 ]; then
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
	fi

done
