#' Transforming hexadecimal data from .ssd file to a readable format
#'
#' @description This function will transform your .txt file created from the .ssd file into a data frame. This data frame will contain the sample date and kcps values for each element for one sample.
#'
#' @return description The function creates a data frame showing kcps values for each element for the sample.
#'
#' @param hex_data The character string with your hexadecimal data, read into R with the readLines() function.
#'
#' @importFrom stringr str_split str_extract_all str_sub
#' @importFrom dplyr select
#' @importFrom sjmisc str_contains
#' @importFrom tidyr pivot_wider
#' @importFrom magrittr %>%
#'
#' @examples
#' \dontrun{
#' string <- readLines("sample_hex.txt")
#' sample.df <- transformssd(hex_data = string)
#' }
#'
#' @export

transformssd <- function(hex_data) {

  # importing txt file as string and remove spaces
  string <- hex_data
  string <- gsub(" ", "", string)
  if(sjmisc::str_contains(string, "(g|h|i|j|k|l|m|n|o|p|q|r|s|t|u|v|w|G|H|I|J|K|L|M|N|O|P|Q|R|S|T|U|V|W|\\W)") == TRUE) {
    stop("ERROR! Your string contains non-hexadecimal characters/symbols. Hexadecimal values can only include 0-9 and A-F/a-f.")
  }

  #### extracting the elements ####

  # split string at every instance of "/AlgerGFF"
  splitstring <- as.list(stringr::str_split(string, "2F416C676572474646"))

  # then add "/AlgerGFF back on each string
  hex <- "2F416C676572474646"
  splitstring.added <- mapply(paste0, splitstring, hex)

  # extract what's between the space and "/AlgerGFF"
  subsplit <- gsub(".*?(00)(.*?)(2F416C676572474646).*", "\\2", splitstring.added)

  # extract the first 4 characters of these substrings, which are the elements
  subsubsplit <- substr(subsplit, 1, 4)

  # transforming from hex to text
  # first move from matrix to string
  substring <- paste(unlist(subsubsplit), collapse='')

  # then transform data from hex to raw
  raw.substring <- sapply(seq(1, nchar(substring), by=2), function(x) substr(substring, x, x+1))

  # and from raw to text
  text.substring <- rawToChar(as.raw(strtoi(raw.substring, 16L)))

  # moving from string to list
  list.extracted <- stringr::str_extract_all(text.substring, "[A-Z][a-z]|[A-Z//s]")

  # and then to data frame
  unlist.extracted <- unlist(list.extracted)
  extracted.df <- as.data.frame(unlist.extracted)
  colnames(extracted.df) <- "Element"

  #### extracting the kcps values ####

  # creating a matrix with the values in hex
  subsplit1 <- gsub(".*?(204B41)(.*?)(2A0020).*", "\\2", splitstring.added)
  subsubsplit1 <- stringr::str_sub(subsplit1, start = -8)
  subsubsplit1 <- subsubsplit1[-1]

  # transforming hex to 32 bit float number
  values.df <- data.frame()
  for (i in 1:length(subsubsplit1)) {
    a <- readBin(as.raw(strtoi(apply(matrix(strsplit(subsubsplit1,"")[[i]],2),2,paste, collapse=""), 16)), "double", size=4)
    values.df <- rbind(values.df, data.frame(t(a), row.names = NULL))
  }

  colnames(values.df) <- "kcps"

  # combining this data frame with the one showing the elements
  elements.values.df <- cbind(extracted.df, values.df)

  #### extracting the sample name ####

  samplename <- substr(string, 17, 100)
  # assumes that the sample name is shorter than 41 characters

  # transforming from string to raw
  raw.samplename <- sapply(seq(1, nchar(samplename), by=2), function(x) substr(samplename, x, x+1))

  # and from raw to text
  text.samplename <- rawToChar(as.raw(strtoi(raw.samplename, 16L)))

  # adding the sample name to the data frame
  element.values.name.df <- cbind(elements.values.df, Sample = text.samplename)

  #### extracting the date ####

  date <- substr(string, 337, 376)

  # transforming from string to raw
  raw.date <- sapply(seq(1, nchar(date), by=2), function(x) substr(date, x, x+1))

  # and from raw to text
  text.date <- rawToChar(as.raw(strtoi(raw.date, 16L)))

  # changing format of date
  text.date <- gsub("-", ".", text.date)
  if(sjmisc::str_contains(text.date, "Jan") == TRUE) {
    text.date <- gsub("Jan", "01", text.date)
  } else if(sjmisc::str_contains(text.date, "Feb") == TRUE) {
    text.date <- gsub("Feb", "02", text.date)
  } else if(sjmisc::str_contains(text.date, "Mar") == TRUE) {
    text.date <- gsub("Mar", "03", text.date)
  } else if(sjmisc::str_contains(text.date, "Apr") == TRUE) {
    text.date <- gsub("Apr", "04", text.date)
  } else if(sjmisc::str_contains(text.date, "Mai") == TRUE) {
    text.date <- gsub("Mai", "05", text.date)
  } else if(sjmisc::str_contains(text.date, "Jun") == TRUE) {
    text.date <- gsub("Jun", "06", text.date)
  } else if(sjmisc::str_contains(text.date, "Jul") == TRUE) {
    text.date <- gsub("Jul", "07", text.date)
  } else if(sjmisc::str_contains(text.date, "Aug") == TRUE) {
    text.date <- gsub("Aug", "08", text.date)
  } else if(sjmisc::str_contains(text.date, "Sep") == TRUE) {
    text.date <- gsub("Sep", "09", text.date)
  } else if(sjmisc::str_contains(text.date, "Okt") == TRUE) {
    text.date <- gsub("Okt", "10", text.date)
  } else if(sjmisc::str_contains(text.date, "Nov") == TRUE) {
    text.date <- gsub("Nov", "11", text.date)
  } else {
    text.date <- gsub("Des", "12", text.date)
  }

  # adding the date to the data frame
  element.values.name.date.df <- cbind(element.values.name.df, Date = text.date)

  #### formatting ####

  # adding " (Int)" to element names to match .txt file created by XRF machine
  element.values.name.date.df$Element <- paste0(element.values.name.date.df$Element, " (Int)")

  # pivoting wider to match .txt file created by XRF machine
  element.values.name.date.df <- element.values.name.date.df %>%
    tidyr::pivot_wider(names_from = Element, values_from = kcps)

  return(element.values.name.date.df)

}
