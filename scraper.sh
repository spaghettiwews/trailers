#!/bin/sh

END_YEAR=2015
END_MONTH=1
CURRENT_YEAR=$(date +"%Y")
CURRENT_MONTH=$(date +"%_m" | xargs)
YEAR=$CURRENT_YEAR
BASE_URL="https://www.theverge.com/archives/film"
PAGE_URL_REGEX="https:\/\/[A-Za-z0-9\-\.\/\-]*"
TRAILER_REGEX="<iframe src=\"https:\/\/www\.youtube\.com.+rel=0.+<\/iframe>"
LAST_UPDATED=$(date +"%A,%e %B %Y @ %T")

echo "<!DOCTYPE html><html lang='en'><head><meta charset='UTF-8'><meta name='viewport' content='width=device-width, initial-scale=1.0'><script src='https://cdn.jsdelivr.net/npm/vanilla-lazyload@15.1.1/dist/lazyload.min.js'></script><title>Trailers | ${LAST_UPDATED}</title></head><body><style>iframe{position:relative!important;width:600px!important;height:320px!important;display:block;margin:1rem auto;}h2{max-width: 600px;margin: 2rem auto;font-family: monospace;}</style><h2>Last checked: ${LAST_UPDATED}</h2>" > index.html

while [ $YEAR -ge $END_YEAR ]
do
    MONTH=1
    if [ "$YEAR" == "$CURRENT_YEAR" ]
        then
            MONTH=$CURRENT_MONTH
        else
            MONTH=12
    fi
    while [ $MONTH -ge $END_MONTH ]
    do
        echo ${BASE_URL}/${YEAR}/${MONTH}
        {
            curl -s --compressed "${BASE_URL}/${YEAR}/${MONTH}" | 
            grep -o -E "${PAGE_URL_REGEX}" | 
            grep -E "trailers?" |
            xargs curl -s --compressed |
            grep -o -E "${TRAILER_REGEX}" |
            sed s/"<iframe src"/"<iframe data-src"/g |
            cat >> index.html
        }
        ((MONTH--))
    done
    ((YEAR--))
done

echo '<script>document.addEventListener("DOMContentLoaded",function(){var lazyLoadInstance=new LazyLoad({elements_selector:"iframe"});});</script></body></html>' >> index.html