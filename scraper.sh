#!/bin/sh

PAGINATE=50
PAGER=""
STYLE="body{max-width:1000px;margin:0 auto;padding:0 1rem;}.wrapper{margin:0 auto 1rem;max-width:1000px;padding:56.25% 0 0 0;position:relative;}iframe{position:absolute;top:0;left:0;width:100%;height:100%;}h2{max-width:1000px;margin:2rem auto;font-family:monospace;}.pagination{list-style:none;display:flex;padding:0;max-width:1000px;margin:2rem auto;flex-wrap: wrap;}.pagination>li{padding:0.5rem;}"

scrape() {
    local END_YEAR=2020
    local END_MONTH=1
    local CURRENT_YEAR=$(date +"%Y")
    local CURRENT_MONTH=$(date +"%_m" | xargs)
    local YEAR=$CURRENT_YEAR
    local BASE_URL="https://www.theverge.com/archives/film"
    local PAGE_URL_REGEX="https:\/\/[A-Za-z0-9\-\.\/\-]*"
    local TRAILER_REGEX="<iframe src=\"https:\/\/www\.youtube\.com.+rel=0.+<\/iframe>"

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
                sed s@"<iframe src"@"<div class='wrapper'><iframe data-src"@g |
                sed s@"</iframe>"@"</iframe></div>"@g |
                cat >> public/tmp
            }
            ((MONTH--))
        done
        ((YEAR--))
    done
}

paginate() {
    local COUNT=0
    local FILENAME="index.html"
    local LAST_UPDATED=$(date +"%A,%e %B %Y @ %T")

    while read -r line
    do 
        if [[ ($(( COUNT % $1 )) -eq 0) && (COUNT -ne 0) ]]
        then
            local PAGE_NUMBER=$((COUNT / $1))
            FILENAME="${PAGE_NUMBER}.html"
        fi
        if [[ ($(( COUNT % $1 )) -eq 0) || (COUNT -eq 0) ]]
        then
            echo "<!DOCTYPE html><html lang='en'><head><meta charset='UTF-8'><meta name='viewport' content='width=device-width, initial-scale=1.0'><script src='https://cdn.jsdelivr.net/npm/vanilla-lazyload@15.1.1/dist/lazyload.min.js'></script><title>Trailers | ${LAST_UPDATED}</title></head><body><style>${STYLE}</style><h2>Last checked: ${LAST_UPDATED}</h2>" > public/$FILENAME
        fi
        echo $line >> public/$FILENAME
        ((COUNT++))
    done < public/tmp

    for FILE in public/*.html
    do
        echo '<!--pagination goes here-->' >> $FILE
        echo '<script>document.addEventListener("DOMContentLoaded",function(){var lazyLoadInstance=new LazyLoad({elements_selector:"iframe"});});</script></body></html>' >> $FILE
    done
}

build_pager() {
    PAGER+="<ul class='pagination'>"
    for file in public/*.html
    do
        local PAGE_FILENAME=${file##*/}
        local PAGE_NAME=(${PAGE_FILENAME%%.*})
        PAGER+="<li><a href='${PAGE_FILENAME}'>${PAGE_NAME}</a></li>"
    done
    PAGER+="</ul>"
}

add_pager() {
    for file in public/*.html
    do
        sed -i s@"<!--pagination goes here-->"@"${PAGER}"@g $file
    done    
}

rm -rf  public/tmp public/*.html
scrape
paginate $PAGINATE
build_pager
add_pager