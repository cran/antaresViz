# Copyright © 2016 RTE Réseau de transport d’électricité

#' @rdname exchangesStack 
#' @export
#' 

exchangesStackAliases <- function() {
  for (n in names(pkgEnv$exchangesStackAliases)) {
    alias <- pkgEnv$exchangesStackAliases[[n]]
    
    cat("\n", n, "\n===========\n", sep = "")
    cat(alias$description, "\n")
    
    # Stacks definition
    names <- names(alias$variables)
    formulas <- vapply(alias$variables, FUN.VALUE = character(1), function(x) {
      as.character(as.expression(x))
    })
    formulas <- sprintf('"%s" = %s', names, formulas)
    
    
    cat("-----------\n  variables = alist(\n    ")
    cat(paste(formulas, collapse = ",\n    "))
    cat("\n  )")
    
    # Stack colors
    colors <- sprintf('"%s"', alias$colors)
    cat(sprintf(",\n\n  colors = c(%s)", paste(colors, collapse = ", ")))
    
    if (length(alias$lines) > 0) {
      # Lines definition
      names <- names(alias$lines)
      formulas <- vapply(alias$lines, FUN.VALUE = character(1), function(x) {
        as.character(as.expression(x))
      })
      formulas <- sprintf('"%s" = %s', names, formulas)
      
      cat(",\n\n  lines = alist(\n    ")
      cat(paste(formulas, collapse = ",\n    "))
      cat("\n  )")
      
      # Line colors
      colors <- sprintf('"%s"', alias$lineColors)
      cat(sprintf(",\n\n  lineColors = c(%s)", paste(colors, collapse = ", ")))
      
      # Line width
      width <- sprintf('"%s"', alias$lineWidth)
      cat(sprintf(",\n\n  lineWidth = c(%s)", paste(width, collapse = ", ")))
    }
    cat("\n")
  }
}

#' @rdname exchangesStack
#' @export
#' 

setExchangesStackAlias <- function(name, variables, colors, lines = NULL, 
                                       lineColors = NULL, lineWidth = 3, description = NULL) {
  if (is.null(description)) description <- name
  
  if (length(variables) != length(colors)) {
    stop("Number of colors and number of variables should be equal.")
  }
  
  if (length(lines) != length(lineColors)) {
    stop("Number of line colors and number of lines should be equal.")
  }
  
  if(length(lines) > 0){
    same_name <- intersect(names(variables), names(lines))
    if(length(same_name) > 0){
      stop("Can't use same name(s) for both variables and lines : '", 
           paste(same_name, collapse = "', '"), "'.")
    }
  }
  
  if(length(lineWidth) == 0){
    lineWidth <- rep(3, length(lines))
  } else if(length(lineWidth) == 1){
    lineWidth <- rep(lineWidth, length(lines))
  } else {
    if (length(lines) != length(lineWidth)) {
      stop("Number of line Width and number of lines should be equal.")
    }
  }
  
  pkgEnv$exchangesStackAliases[[name]] <- list(
    description = description,
    variables = variables,
    colors = colors
  )
  
  if (!is.null(lines)) {
    pkgEnv$exchangesStackAliases[[name]]$lines <- lines
    pkgEnv$exchangesStackAliases[[name]]$lineColors <- lineColors
    pkgEnv$exchangesStackAliases[[name]]$lineWidth <- lineWidth
  }
  
  invisible(NULL)
}