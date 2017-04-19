#!/bin/bash

cd "$(dirname "$0")"

HDRFILE='../src/ccxll.h'
PDFFILE='ccxll-call.pdf'

TEM_DOT='ccxll-call.tem.dot'
TEM_SVG='ccxll-call.tem.svg'

CURTIME="$(LANG=en_US date '+%b %Y')"

PREPROC="$(gcc -fpreprocessed              \
            -w -dD -E "$HDRFILE" |         \
           sed ':a;N;$!ba;s/\\\n//g' |     \
           grep ^#define |                 \
           awk '{$1="" ; print "#" $0}' |  \
           sed 's/[^#a-zA-Z0-9_]/ /g' |    \
           sed 's/##/ /g' | tr -s ' ')"

PATTERN="$(echo "$PREPROC" |               \
           awk '{print $2}' |              \
           paste -sd "\n" && echo '#')"

echo "$PATTERN" > 'PATTERN'

# SET ='@' if ignored
BLACKLS='OPENGC3_CCXLL_H\|XOR\|ccxll\|CCXLL\|'`
       `'CCXLL_CONT\|CCXLL_NODE\|CCXLL_BLCK\|CCXLL_ITER\|'`
       `'CCXLL_HDTL\|CCXLL_ADJC\|ccxll_append'

MATCHED="$(echo "$PREPROC" |               \
           tr ' ' '\n' |                   \
           LC_ALL=C grep -w -f 'PATTERN' | \
           grep -v -w "$BLACKLS" |         \
           tr '\n' ' ' |                   \
           sed 's/# /\n/g' |               \
           sed '/^$/d' && echo '')"

DOTFRMT='{printf $1" -> ";$1="{";print $0" }"}'

WHITELS='ccxll '

DIGRAPH="$(echo "$WHITELS" "$MATCHED" | awk "$DOTFRMT")"

DOTFILE="$(m4 "$TEM_DOT" && echo -e "$DIGRAPH" '\n } ')"

SVGFILE="$(dot -Tsvg <<< "$DOTFILE" | head -n -1 &&   \
           cat "$TEM_SVG" | sed "s/\[CURTIME\]/$CURTIME/g")"

SVG2PDF="$(rsvg-convert -f 'pdf' <<< "$SVGFILE" >'PDF_RAW')"

PDFCROP="$(pdfcrop --margins '64' 'PDF_RAW' "$PDFFILE")"

rm 'PATTERN' 'PDF_RAW'