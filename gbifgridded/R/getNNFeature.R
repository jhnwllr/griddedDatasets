#' Add taxon info to a data.frame.
#'
#' @param .data data.frame to be passed in probably through a pipe %>%
#' @param key unquoted column name for taxonkeys to be passed in
#' @return Returns data.frame of results.
#' @examples
#'
#'\dontrun{
#'
#' D %>% addTaxonInfo(specieskey)
#'
#'}
#'

getNNFeature = function(D,key,k) { # nearest neighbor features

  # Subset data by focal key
  D = D %>% filter(datasetKey == key)


  # Nearest Neighbor Percent Feature
  NN = FNN::get.knn(cbind(D$decimalLongitude,D$decimalLatitude), k=k)$nn.dist # nearest neighbors

  # Set minimum distance
  minimum = 0.01

  NN = round(NN,2) # round nearest neighbors nearest 0.01
  # NN = plyr::round_any(NN,0.01,ceiling) # adjust precision of rounding

  TL = apply(NN,2,table) # table list
  boolL = lapply(TL,function(x) as.numeric(names(x)) > minimum) # distances less than minimum
  T = list(); for(i in 1:length(TL)) T[[i]] = TL[[i]][boolL[[i]]] # filter out those distances less than minimum

  NNC = sapply(T,function(x) rev(sort(x))[1]) # NN point count
  NNPF = sapply(T,function(x) rev(sort(x))[1]/sum(x)) # NN percent feature.

  # Other features
  MCD = as.numeric(names(NNPF)) # most common distances of 4 NN
  NNPLM = apply(NN,2,function(x) sum(x <= minimum))/nrow(NN)  # percent less than minimum

  NNF = cbind(
    rbind(NNC) %>% as.data.frame() %>% setNames(paste0("NNC",1:k)),
    rbind(NNPF) %>% as.data.frame() %>% setNames(paste0("NNPF",1:k)),
    rbind(MCD) %>% as.data.frame() %>% setNames(paste0("MCD",1:k)),
    rbind(NNPLM) %>% as.data.frame() %>% setNames(paste0("NNPLM",1:k))
  )

  NNF$key = key # add key
  NNF$uniqueLatLon = nrow(D)

  return(NNF) # return the nearest neighbor feature
}
