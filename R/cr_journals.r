#' Search CrossRef journals
#'
#' BEWARE: The API will only work for CrossRef DOIs.
#'
#' @export
#' 
#' @param issn One or more ISSN's. Format is XXXX-XXXX.
#' @template args
#' @template moreargs
#' @param works (logical) If TRUE, works returned as well, if not then not.
#' @details Note that some parameters are ignored unless \code{works=TRUE}: sample, sort, 
#' order, filter
#' @examples \dontrun{
#' cr_journals()
#' cr_journals(issn="2167-8359")
#' cr_journals(issn="2167-8359", works=TRUE)
#' cr_journals(issn=c('1803-2427','2326-4225'))
#' cr_journals(query="ecology")
#' cr_journals(issn="2167-8359", query='ecology', works=TRUE, sort='score', order="asc")
#' cr_journals(issn="2167-8359", query='ecology', works=TRUE, sort='score', order="desc")
#' cr_journals(issn="2167-8359", works=TRUE, filter=c(from_pub_date='2014-03-03'))
#' cr_journals(query="peerj")
#' cr_journals(issn='1803-2427', works=TRUE)
#' cr_journals(issn='1803-2427', works=TRUE, sample=1)
#' cr_journals(limit=2)
#' }

`cr_journals` <- function(issn = NULL, query = NULL, filter = NULL, offset = NULL,
  limit = NULL, sample = NULL, sort = NULL, order = NULL, works=FALSE, .progress="none", ...)
{
  foo <- function(x){
    path <- if(!is.null(x)){
      if(works) sprintf("journals/%s/works", x) else sprintf("journals/%s", x)
    } else { "journals" }
    filter <- filter_handler(filter)
    args <- cr_compact(list(query = query, filter = filter, offset = offset, rows = limit,
                            sample = sample, sort = sort, order = order))
    cr_GET(endpoint = path, args, todf = FALSE, ...)
  }
  
  if(length(issn) > 1){
    res <- llply(issn, foo, .progress=.progress)
    res <- lapply(res, "[[", "message")
    res <- lapply(res, parse_works)
    df <- rbind_all(res)
    df$issn <- issn
    df
  } else {
    tmp <- foo(issn)
    if(!is.null(issn)){
      if(works){ 
        meta <- parse_meta(tmp)
        dat <- rbind_all(lapply(tmp$message$items, parse_works)) 
      } else {
        meta <- NULL
        dat <- parse_journal(tmp$message)
      }
      list(meta=meta, data=dat)
    } else {
      fxn <- if(works) parse_works else parse_journal
      meta <- parse_meta(tmp)
      list(meta=meta, data=rbind_all(lapply(tmp$message$items, fxn)))
    }
  }
}

parse_journal <- function(x){
  names(x$flags) <- names2underscore(names(x$flags))
  names(x$coverage) <- names2underscore(names(x$coverage))
  names(x$counts) <- names2underscore(names(x$counts))
  data.frame(title=x$title, publisher=x$publisher, issn=paste_longer(x$ISSN[[1]]), 
             last_status_check_time=convtime(x$`last-status-check-time`),
             x$flags,
             x$coverage,
             x$counts,
             stringsAsFactors = FALSE)
}

paste_longer <- function(w) if(length(w) > 1) paste(w, sep=", ") else w
names2underscore <- function(w) sapply(w, function(z) gsub("-", "_", z), USE.NAMES = FALSE)