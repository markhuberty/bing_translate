bing_translate
==============

R code for translating text via the Bing Translate API.

Introduction
-------------

~bing_translate~ provides a simple interface for formatting text and submitting it to the Bing Translate API. It loads raw text as a UTF-8 formatted string, formats the text as a valid URL For submission, and translates the text via the Bing Translate API. The core translation functions attempt to detect the language of the input text, and will only translate if the input language is not the same as the output language. Basic error handling and delay routines attempt o avoid offending the API usage rules. 

    ## Basic usage:
    ## Read in the files as a character vector and encode
    filename.list <- c("file1.txt", "file2.txt")
    files <- lapply(filename.list, bing.read.file)
    formatted.text <- lapply(files, function(x){

      out <- bing.format(text.file=x,
                         encoding="URL",
                         char.limit=1000
                         )
    }  
        )

    ## Then translate:
    apiID <- "myapiid"
    translated.text <- bing.translate(formatted.text,
                                      lang.out="en",
                                      apikey=apiID
                                      )
                                          
*NOTE*: You are responsible for making sure that you understand and follow the Bing API limits. See [here](http://social.msdn.microsoft.com/Forums/eu/microsofttranslator/thread/d837a761-eca6-4e86-979c-ff24e2ec3397) for more detail.

