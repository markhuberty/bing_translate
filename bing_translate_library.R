#################################################
## bing.translate.library.R
## Author: Mark Huberty
## Begun: 19 January 2012
## Description: Provides a basic R interface to Bing's
##              machine translation library
## NOTE: You are responsible for not abusing Bing's terms of use.
##       The API calls here provide some help in doing this, but
##       for the rest you are on your own.
##################################################

require(RCurl)
require(foreach)
require(XML)
require(stringr)

## read.file takes input in UTF-8 format from a plaintext
## Inputs: file.location, a valid file and path to the text file
## Outputs: a list of strings, each one corresponding to a single
##          line in the text file
read.file <- function(file.location){
  con <- file(file.location)
  open(con)
  results.list <- list()
  current.line <- 1
  while(length(line <- readLines(con, n=1, warn=FALSE, encoding="UTF-8")) > 0)
    {

      results.list[[current.line]] <- line
      #print(nchar(results.list[[current.line]]))

      current.line <- current.line + 1

    }
  close(con)

  return(results.list)
}


## encode.list takes as input a list of strings as output from
## read.file and encodes it as a URL for submission to bing
## Inputs: text.list: the output of read.file
## Outputs: a list of length text.list, encoded as URL
encode.list <- function(text.list){

  out <- lapply(text.list, function(x){

    ## Encode
    url.encoded <- URLencode(x)

    ## Strip out leading spaces
    url.encoded <- gsub("^[%ca20]*", "", url.encoded)

    ## Strip out multiple spaces
    url.encoded <- gsub("(%c2%a0){1,}", "%20", url.encoded)

    ## Strip out non-encoded spaces
    url.encoded <- gsub(" +", "", url.encoded)

    return(url.encoded)
  })

  return(out)

}


## bing.format reads in data from a text file, encodes it
## as a url, and chops it up into subsections of valid lengths for submission
## to bing.
## Inputs: text.file, a valid filepath and text file
##         encoding: one of URL or NULL; URL is required for later
##                   use with the bing translator
##         char.limit: how long should a single request be? Bing's API
##                     suggests 2000 characters is the limit.
## Outputs: A list of url-encoded strings 
bing.format <- function(text.file, encoding="URL", char.limit=2000){

  results.list <- read.file(text.file)

  if(encoding=="URL")
    results.list <- encode.list(results.list)
  
  this.idx <- 1
  results.idx <- 1
  results.out <- list()

  print(paste("results.list length = ", length(results.list)))
  while(results.idx <= length(results.list))
    {
      print(results.idx)
      results.out[[this.idx]] <- results.list[[results.idx]]
      results.idx <- results.idx + 1
      

      ## If this completes the loop, skip the rest
      if(results.idx > length(results.list))
        {
          break
        }

      ## Otherwise, concatenate until the string is going to
      ## exceed char.limit characters
      while((nchar(results.out[[this.idx]]) +
             nchar(results.list[[results.idx]])) < char.limit &
            results.idx <= length(results.list)
            )
        {
          
          results.out[[this.idx]] <- paste(results.out[[this.idx]],
                                           results.list[[results.idx]],
                                           sep="%20"
                                           )
          
          results.idx <- results.idx + 1

          if(results.idx > length(results.list))
            break
        }

      results.out[[this.idx]] <- gsub(" +", "", results.out[[this.idx]]) 
      this.idx <- this.idx + 1
      print(paste("this.idx = ", this.idx))
    }
    

  return(results.out)
}


## bing.detect submits a string to the Bing Detect API and
## receives back the language code for the language that Bing thinks
## string is in.
## Inputs: text: a valid URL-encoded text string
##         apikey: a valid Bing apikey
## Outputs: an ISO-compliant two-letter language code
bing.detect <- function(text, apikey){

  bing.url <-
    paste("http://api.microsofttranslator.com/v2/Http.svc/Detect?appId=",
          apikey,
          "&text=",
          text,
          sep=""
          )

  detect.successful <- FALSE
  while(!detect.successful)
    {

      detect.out <- try(getURL(bing.url))

      if(class(detect.out) != "try-class" &
         !grepl("Exception", detect.out)){
        
        detect.successful <- TRUE
        
      }
    }  
      
  detect.out <- xmlToList(detect.out)[[1]]
  
  return(detect.out)

}


## translate.formatted.string takes a string to be translated and returns a translated
## string. Users can specify the desired translation language.
## Inputs: text: a valid url-encoded text string
##         lang.in: the ISO language code for the string
##         lang.out: the language to translate the string int
##         apikey: a valid Bing api key
## Outputs: A translated version of the input string
translate.formatted.string <- function(text, lang.in, lang.out="en", apikey){
  bing.url <-
    paste("http://api.microsofttranslator.com/v2/Http.svc/Translate?appId=",
          apiID,
          "&text=",
          text,
          "&from=", ## Assume here that it detects the lang automatically
          lang.in,## lang.from,
          "&to=",
          lang.out,
          sep=""
          )

  translate.successful <- FALSE
  while(!translate.successful)
    {
      translate.string <-try(getURL(bing.url))
      
      if(class(translate.string) != "try-error" &
         !grepl("servertoobusy", translate.string))
        translate.successful <- TRUE
    }
  translate.string <- xmlToList(translate.string)
  
  return(translate.string)

}


## bing.translate takes as input a list of lists of text strings
## (representing multiple documents, each chopped up and encoded)
## and translates them all. If the string is already in the right language,
## it just re-assembles the string from the input
## Inputs: text.list: a list of documents, each represented as
##                    a set of URL-encoded strings
##         lang.out: a valid 2-letter ISO language code
##         apikey: a valid Bing api key
## Outputs: a list of translated documents, represented as strings
bing.translate <- function(text.list, lang.out, apikey){

  first.time <- TRUE
  list.out <- lapply(text.list, function(x){

    ## print(first.time)
    ## if(!first.time)
    ##   {
    ##     save(list.out, file="./data/translate_temp.RData")
    ##   }
    
    text.in <- x

    if(length(text.in) > 0)
      {
        string.out <- foreach(i=1:length(text.in), .combine=c) %do% {

          ## Check the language ID based on the first
          ## chunk of of the text
          if(nchar(text.in[[i]]) > 0)
            {
              if(i == 1)
                {
                  print("Checking language")

                  lang.in <<- bing.detect(text=text.in[[i]],
                                          apikey=apikey
                                          )

                  print(lang.in)
                }

              ## For if not english, translate,
              ## otherwise just return the string
              if(!is.null(lang.in))
                {
                  if(lang.in != lang.out)
                    {
                      print("translating")
                      en.string <- translate.formatted.string(text=text.in[[i]],
                                                              lang.in=lang.in,
                                                              lang.out=lang.out,
                                                              apikey=apikey
                                                              )
                      
                      ## If I called the translate API,
                      ## slow things down to avoid rate limiting
                      ## Note the addition of noise
                      ## Note abs call on noise to ensure it's always
                      ## positive.
                      Sys.sleep(2 + abs(rnorm(n=1, mean=1)))
                      
                    }else{
                      print("No translation needed, moving on")

                      ## Strip out the URL encoding 
                      en.string <- gsub("%20", " ", text.in[[i]])
                    }
                }else{
                  en.string <- ""
                }


            }else{

              en.string <- ""

            }
          ## Return the string
          return(en.string)
          

        }

        ## Collapse the vector of strings into a single string
        string.out <- paste(string.out, collapse=" ")
        
        first.time <<- FALSE
        return(string.out)
      }
  })

  return(list.out)
  
}


## Basic usage:
## First encode the files
## raw.ocr.bing <- lapply(files, function(x){

## out <- bing.format(text.file=x,
##                      encoding="URL",
##                      char.limit=1000
##                      )
## }
##      )

## Then translate:
## apiID <- "myapiid"
## translated.text <- bing.translate(raw.ocr.bing,
##                                   lang.out="en",
##                                   apikey=apiID
##                                   )

