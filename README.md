bing_translate
==============

R code for translating text via the Bing Translate API.

Introduction
-------------

~bing_translate~ provides a simple interface for formatting text and submitting it to the Bing Translate API. To use it, first pass a vector of texts to be translated through ~read.fun.bing~ for formatting according to Bing's character limits. Then translate it. The core translation functions provide basic response error handling and try to avoid offending the API usage rules. 

    ## Basic usage:
    ## First encode the files
    raw.ocr.bing <- lapply(files, function(x){

    out <- read.fun.bing(text.file=x,
                         encoding="URL",
                         char.limit=1000
                         )
    }  
        )

    ## Then translate:
    apiID <- "myapiid"
    translated.text <- bing.translate.fun(raw.ocr.bing,
                                          lang.out="en",
                                          apikey=apiID
                                          )
                                          
*NOTE*: You are responsible for making sure that you understand and follow the Bing API limits. See [here](http://social.msdn.microsoft.com/Forums/eu/microsofttranslator/thread/d837a761-eca6-4e86-979c-ff24e2ec3397) for more detail.

