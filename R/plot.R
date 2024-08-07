# Copyright © 2016 RTE Réseau de transport d’électricité

#' plot time series contained in an antaresData object
#' 
#' This function generates an interactive plot of an antares time series.
#' 
#' @param x
#'   Object of class \code{antaresData}. Alternatively, it can be a list of 
#'   \code{antaresData} objects. In this case, one chart is created for each
#'   object. Can also be opts object from h5 file or list of opts object from h5 file.
#' @param table
#'   Name of the table to display when \code{x} is an \code{antaresDataList}
#'   object.
#' @param variable
#'   Name of the variable to plot. If this argument is missing, then the 
#'   function starts a shiny gadget that let the user choose the variable to
#'   represent. When the user clicks on the "Done" button", the graphic is
#'   returned by the function.
#' @param elements
#'   Vector of "element" names indicating for which elements of 'x' should the
#'   variable be plotted. For instance if the input data contains areas, then
#'   this parameter should be a vector of area names. If data contains clusters
#'   data, this parameter has to be the concatenation of the area name and the
#'   cluster name, separated by \code{" > "}. This is to prevent confusion 
#'   when two clusters from different areas have the same name.
#' @param variable2Axe \code{character}, variables on second axis.
#' @param type
#'   Type of plot to draw. "ts" creates a time series plot, "barplot" creates
#'   a barplot with one bar per element representing the average value of the
#'   variable for this element. "monotone" draws the monotone curve of the 
#'   variable for each element.
#' @param dateRange
#'   A vector of two dates. Only data points between these two dates are 
#'   displayed. If NULL, then all data is displayed.
#' @param typeConfInt \code{logical}. If multiple Monte Carlo scenarios are present in 
#'   the input data, see all curves (FALSE, Default), or mean and confidence interval (TRUE)
#' @param confInt
#'   Number between 0 and 1 indicating the size of the confidence interval to 
#'   display. If it equals to 0, then confidence interval is not computed nor
#'   displayed. Used only when multiple Monte Carlo scenarios are present in 
#'   the input data.
#' @param minValue
#'   Only used if parameter \code{type} is "density" or "cdf". If this parameter
#'   is set, all values that are less than \code{minValue} are removed from the 
#'   graphic. This is useful to deal with variables containing a few extreme
#'   values (generally cost and price variables). If \code{minValue} is unset,
#'   all values are displayed.
#' @param maxValue
#'   Only used if parameter \code{type} is "density" or "cdf". If this parameter 
#'   is set, all values not in [-minValue, maxValue] are removed from the graphic.
#'   This is useful to deal with variables containing a few extreme values
#'   (generally cost and price variables). If \code{maxValue} is 0 or unset, all
#'   values are displayed.
#' @param aggregate
#'   When multiple elements are selected, should the data be aggregated. If
#'   "none", each element is represented separetly. If "mean" values are
#'   averaged and if "sum" they are added. You can also compute mean and sum by variable.
#' @param colors
#'   Vector of colors
#' @param ylab
#'   Label of the Y axis.
#' @param colorScaleOpts
#'   A list of parameters that control the creation of color scales. It is used
#'   only for heatmaps. See [colorScaleOptions()] for available
#'   parameters.
#' @param xyCompare
#'   Use when you compare studies, can be "union" or "intersect". If union, all
#'   of mcYears in one of studies will be selectable. If intersect, only mcYears in all
#'   studies will be selectable.
#' @param highlight highlight curve when mouse over
#' @param secondAxis add second axis to graph
#' @param h5requestFiltering Contains arguments used by default for h5 request,
#'   typically h5requestFiltering = list(mcYears = 2)
#' @inheritParams prodStack
#'   
#' @return 
#' The function returns an object of class "htmlwidget". It is generated by
#' package \code{highcharter} if time step is annual or by \code{dygraphs} for 
#' any other time step.It can be directly displayed in the viewer or be stored
#' in a variable for later use.
#' 
#' @details 
#' If the input data contains several Monte-Carlo scenarios, the function will
#' display the evolution of the average value. Moreover it will represent a
#' 95% confidence interval.
#' 
#' If the input data has a annual time step, the function creates a barplot
#' instead of a line chart.
#' 
#' compare argument can take following values :
#' \itemize{
#'    \item "mcYear"
#'    \item "main"
#'    \item "variable"
#'    \item "type"
#'    \item "typeConfInt"
#'    \item "confInt"
#'    \item "elements"
#'    \item "aggregate"
#'    \item "legend"
#'    \item "highlight"
#'    \item "stepPlot"
#'    \item "drawPoints"
#'    \item "secondAxis"
#'  }
#' 
#' @examples 
#' \dontrun{
#' mydata <- readAntares(areas = "all", timeStep = "hourly")
#' plot(x = mydata)
#' 
#' # Plot only a few areas
#' plot(x = mydata[area %in% c("area1", "area2", "area3")])
#' 
#' # If data contains detailed results, then the function adds a confidence
#' # interval
#' dataDetailed <- readAntares(areas = "all", timeStep = "hourly", mcYears = 1:2)
#' plot(x = dataDetailed)
#' 
#' # If the time step is annual, the function creates a barplot instead of a
#' # linechart
#' dataAnnual <- readAntares(areas = "all", timeStep = "annual")
#' plot(x = dataAnnual)
#' 
#' # Compare two simulaitons
#' # Compare the results of two simulations
#' setSimulationPath(path1)
#' mydata1 <- readAntares(areas = "all", timeStep = "daily")
#' setSimulationPath(path2)
#' mydata2 <- readAntares(areas = "all", timeStep = "daily")
#' 
#' plot(x = list(mydata1, mydata2))
#' 
#' # When you compare studies, you have 2 ways to defind inputs, union or intersect.
#' # for example, if you chose union and you have mcYears 1 and 2 in the first study
#' # and mcYears 2 and 3 in the second, mcYear input will be worth c(1, 2, 3)
#' # In same initial condition (study 1 -> 1,2 ans study 2 -> 2, 3) if you choose intersect,
#' # mcYear input will be wort 2.
#' # You must specify union or intersect with xyCompare argument (default union).
#' plot(x = list(mydata1[area %in% c("a", "b")],
#'  mydata1[area %in% c("b", "c")]), xyCompare = "union")
#' plot(x = list(mydata1[area %in% c("a", "b")],
#'  mydata1[area %in% c("b", "c")]), xyCompare = "intersect")
#' 
#' # Compare data in a single simulation
#' # Compare two periods for the same simulation
#' plot(x = mydata1, compare = "dateRange")
#' 
#' # Compare two Monte-Carlo scenarios
#' detailedData <- readAntares(areas = "all", mcYears = "all")
#' plot(x = detailedData, .compare = "mcYear")
#' 
#' # Use h5 for dynamic request / exploration in a study
#' # Set path of simulaiton
#' setSimulationPath(path = path1)
#' 
#' # Convert your study in h5 format
#' writeAntaresH5(path = mynewpath)
#' 
#' # Redefine sim path with h5 file
#' opts <- setSimulationPath(path = mynewpath)
#' plot(x = opts)
#' 
#' # Compare elements in a single study
#' plot(x = opts, .compare = "mcYear")
#' # Compare 2 studies
#' plot(x = list(opts, opts2))
#' 
#' # Compare 2 studies with argument refStudy 
#' plot(x = opts, refStudy = opts2)
#' plot(x = opts, refStudy = opts2, type = "ts", interactive = FALSE, mcYearh5 = 2)
#' plot(x = opts, refStudy = opts2, type = "ts", 
#'     dateRange = DR, 
#'     h5requestFiltering = list(mcYears = mcYears = mcYearToTest))
#' 
#' 
#' }
#' 
#' 
#' 
#' 
#' @export
tsPlot <- function(x,
                   refStudy = NULL,
                   table = NULL, 
                   variable = NULL, 
                   elements = NULL, 
                   variable2Axe = NULL,
                   mcYear = "average",
                   type = c("ts", "barplot", "monotone", "density", "cdf", "heatmap"),
                   dateRange = NULL,
                   typeConfInt = FALSE,
                   confInt = 0,
                   minValue = NULL,
                   maxValue = NULL,
                   aggregate = c("none", "mean", "sum", "mean by variable", "sum by variable"),
                   compare = NULL,
                   compareOpts = list(),
                   interactive = getInteractivity(),
                   colors = NULL,
                   main = NULL,
                   ylab = NULL,
                   legend = TRUE,
                   legendItemsPerRow = 5,
                   colorScaleOpts = colorScaleOptions(20),
                   width = NULL, height = NULL, xyCompare = c("union","intersect"),
                   h5requestFiltering = deprecated(), highlight = FALSE, stepPlot = FALSE, drawPoints = FALSE,
                   secondAxis = FALSE,
                   timeSteph5 = deprecated(),
                   mcYearh5 = deprecated(),
                   tablesh5 = deprecated(), language = "en", 
                   hidden = NULL, ...) {
  
  deprecated_vector_params <- c(lifecycle::is_present(h5requestFiltering),
                                lifecycle::is_present(timeSteph5),
                                lifecycle::is_present(mcYearh5),
                                lifecycle::is_present(tablesh5))
  
  if(any(deprecated_vector_params)){
    lifecycle::deprecate_warn(
      when = "0.18.1", 
      what = "tsPlot(h5requestFiltering)",
      details = "all these parameters are relative to the 'rhdf5' package, 
      which is removed from the dependencies"
    )
    
    h5requestFiltering <- NULL
    timeSteph5 <- NULL
    mcYearh5 <- NULL
    tablesh5 <- NULL
  }
  
  # force (deprecated)
  h5requestFiltering <- NULL
  timeSteph5 <- NULL
  mcYearh5 <- NULL
  tablesh5 <- NULL
  
  
  .check_x(x)
  .check_compare_interactive(compare, interactive)
  
  .check_languages(language)
  .check_h5_param(x, mcYear, interactive)
  
  if(language != "en"){
    variable <- .getColumnsLanguage(variable, language)
    variable2Axe <- .getColumnsLanguage(variable2Axe, language)
  }
  
  # Check hidden
  .validHidden(hidden, c("H5request", "timeSteph5", "tables", "mcYearH5", "table", "mcYear", "variable", 
                         "secondAxis", "variable2Axe", "type", "dateRange", "typeConfInt", "confInt", "minValue", "maxValue",
                         "elements", "aggregate", "legend", "highlight", "stepPlot", "drawPoints", "main"))
  
  #Check compare
  .validCompare(compare,  c("mcYear", "main", "variable", "type", "typeConfInt", "confInt", "elements", "aggregate", "legend", 
                            "highlight", "stepPlot", "drawPoints", "secondAxis"))
  
  if(is.list(compare)){
    if("secondAxis" %in% names(compare)){
      compare <- c(compare, list(variable2Axe = NULL))
    }
  } else if(is.vector(compare)){
    if("secondAxis" %in% compare){
      compare <- c(compare, "variable2Axe")
    }
  }
  
  xyCompare <- match.arg(xyCompare)
  type <- match.arg(type)
  aggregate <- match.arg(aggregate)
  colorScaleOpts <- do.call(colorScaleOptions, colorScaleOpts)
  
  init_elements <- elements
  init_dateRange <- dateRange
  
  if(!is.null(compare) && "list" %in% class(x)){
    if(length(x) == 1) x <- list(x[[1]], x[[1]])
  }
  if(!is.null(compare) && ("antaresData" %in% class(x)  | "simOptions" %in% class(x))){
    x <- list(x, x)
  }
  # .testXclassAndInteractive(x, interactive)
  
  # h5requestFiltering <- .convertH5Filtering(h5requestFiltering = h5requestFiltering, x = x)
  
  
  # Generate a group number for dygraph objects
  if (!("dateRange" %in% compare)) {
    group <- sample(1e9, 1)
  } else {
    group <- NULL
  }
  
  compareOptions <- .compOpts(x, compare)
  if(is.null(compare)){
    if(compareOptions$ncharts > 1){
      compare <- list()
    }
  }
  
  processFun <- function(x, elements = NULL, dateRange = NULL) {
    assert_that(inherits(x, "antaresData"))
    x <- as.antaresDataList(x)
    
    lapply(x, function(x) {
      
      x <- copy(x)
      
      idCols <- .idCols(x)
      
      if(language != "en"){
        ind_to_change <- which(colnames(x) %in% language_columns$en)
        if(length(ind_to_change) > 0){
          new_name <- language_columns[get("en") %in% colnames(x), ]
          v_new_name <- new_name[[language]]
          names(v_new_name) <- new_name[["en"]]
          setnames(x, colnames(x)[ind_to_change], unname(v_new_name[colnames(x)[ind_to_change]]))
        }
      }
      valueCols <- setdiff(names(x), idCols)
      timeStep <- attr(x, "timeStep")
      opts <- simOptions(x)
      
      dt <- x[, .(
        timeId = timeId,
        time = .timeIdToDate(timeId, attr(x, "timeStep"), simOptions(x)), 
        value = 0)
        ]
      
      if ("cluster" %in% idCols) {
        dt$element <- paste(x$area, x$cluster, sep = " > ")
      } else if ("district" %in% idCols) {
        dt$element <- x$district
      } else if ("link" %in% idCols) {
        dt$element <- x$link
      } else if ("area" %in% idCols) {
        dt$element <- x$area
      } else stop("No Id column")
      
      if ("mcYear" %in% names(x)) {
        dt$mcYear <- x$mcYear
      }
      
      dataDateRange <- as.Date(range(dt$time))
      if (is.null(dateRange) || length(dateRange) < 2) dateRange <- dataDateRange
      
      uniqueElem <- sort(as.character(unique(dt$element)))
      if (is.null(elements)) {
        elements <- uniqueElem
        # if (length(elements) > 5) elements <- elements[1:5]
      }
      
      # Function that generates the desired graphic.
      plotFun <- function(mcYear, id, variable, variable2Axe, elements, type, typeConfInt, confInt, dateRange, 
                          minValue, maxValue, aggregate, legend, highlight, stepPlot, drawPoints, main) {
        if (is.null(variable)) variable <- valueCols[1]
        if (is.null(dateRange)) dateRange <- dateRange
        if (is.null(type) || !variable %in% names(x)) {
          return(combineWidgets())
        }
        if(variable[1] == "No Input") {return(combineWidgets(.getLabelLanguage("No data", language)))}
        dt <- .getTSData(
          x, dt, 
          variable = c(variable, variable2Axe), elements = elements, 
          uniqueElement = uniqueElem, mcYear = mcYear, dateRange = dateRange, 
          aggregate = aggregate, typeConfInt = typeConfInt
        )
        
        if (nrow(dt) == 0) return(combineWidgets(.getLabelLanguage("No data", language)))
        
        if(type == "ts"){
          if(!is.null(dateRange))
          {
            if(dt$time[1] > dateRange[1]){
              dt <- dt[c(NA, 1:nrow(dt))]
              dt$time[1] <- dateRange[1]
            }
            nrowTp <- nrow(dt)
            if(dt$time[nrowTp] < dateRange[2]){
              dt <- dt[c(1:nrow(dt), NA)]
              dt$time[nrowTp + 1] <- dateRange[2]
            }
          }
          
        }
        
        f <- switch(type,
                    "ts" = .plotTS,
                    "barplot" = .barplot,
                    "monotone" = .plotMonotone,
                    "density" = .density,
                    "cdf" = .cdf,
                    "heatmap" = .heatmap,
                    stop("Invalid type")
        )
        
        uni_ele <- unique(dt$element)
        if(!is.null(variable2Axe) && length(variable2Axe) > 0){
          label_variable2Axe <- variable2Axe
          variable2Axe <- uni_ele[grepl(paste(paste0("(", variable2Axe, ")"), collapse = "|"), uni_ele)]
        }

        # BP 2017
        # if(length(main) > 0){
        #   mcYear <- ifelse(mcYear == "average", "moyen", mcYear)
        #   if(grepl("h5$", main)){
        #     # main <- paste0(gsub(".h5$", "", main), " : ", areas, " (tirage ", mcYear, ")")
        #     main <- paste0(gsub(".h5$", "", main), " : Tirage ", mcYear)
        #   } else {
        #     # main <- paste0("Production ", areas, " (tirage ", mcYear, ")")
        #     main <- paste0("Tirage ", mcYear)
        #   }
        # }
      
        f(
          dt, 
          timeStep = timeStep, 
          variable = variable, 
          variable2Axe = variable2Axe,
          label_variable2Axe = label_variable2Axe,
          typeConfInt = typeConfInt,
          confInt = confInt, 
          minValue = minValue,
          maxValue = maxValue, 
          colors = colors, 
          main = main, 
          ylab = if(length(ylab) == 1) ylab else ylab[id], 
          legend = legend, 
          legendItemsPerRow = legendItemsPerRow, 
          width = width, 
          height = height,
          opts = opts,
          colorScaleOpts = colorScaleOpts,
          group = group,
          highlight = highlight,
          stepPlot = stepPlot,
          drawPoints = drawPoints,
          language = language
        )
        
      }
      list(
        plotFun = plotFun,
        dt = dt,
        x = x,
        idCols = idCols,
        valueCols = valueCols,
        dataDateRange = dataDateRange,
        dateRange = dateRange,
        uniqueElem = uniqueElem,
        uniqueMcYears = unique(x$mcYear),
        elements = elements,
        timeStep = timeStep,
        opts = opts
      )
    })
  }
  
  # If not in interactive mode, generate a simple graphic, else create a GUI
  # to interactively explore the data
  if (!interactive) {
    listParamH5NoInt <- list(
      timeSteph5 = timeSteph5,
      mcYearh5 = mcYearh5,
      tablesh5 = tablesh5, 
      h5requestFiltering = h5requestFiltering
    )
    params <- .getParamsNoInt(x = x, 
                              refStudy = refStudy, 
                              listParamH5NoInt = listParamH5NoInt, 
                              compare = compare, 
                              compareOptions = compareOptions, 
                              processFun = processFun)
    
    # paramCoe <- .testParamsConsistency(params = params, mcYear = mcYear)
    # mcYear <- paramCoe$mcYear
    if (is.null(table)) table <- names(params$x[[1]])[1]
    if (is.null(mcYear)) mcYear <- "average"
    L_w <- lapply(params$x, function(X){
      X[[table]]$plotFun(mcYear, 1, variable, variable2Axe, elements, type, typeConfInt, confInt, dateRange, 
                         minValue, maxValue, aggregate, legend, highlight, stepPlot, drawPoints, main)
    })
    return(combineWidgets(list = L_w))
    
  }
  
  typeChoices <- c("ts", "barplot",  "monotone", "density", "cdf", "heatmap")
  names(typeChoices) <- c(.getLabelLanguage("time series", language), .getLabelLanguage("barplot", language),
                          .getLabelLanguage("monotone", language), .getLabelLanguage("density", language),
                          .getLabelLanguage("cdf", language), .getLabelLanguage("heatmap", language))
  
  ##remove notes
  table <- NULL
  x_in <- NULL
  paramsH5 <- NULL
  timeSteph5 <- NULL
  mcYearH5 <- NULL
  sharerequest <- NULL
  timeStepdataload <- NULL
  x_tranform <- NULL
  meanYearH5 <- NULL
  
  manipulateWidget({
    # .tryCloseH5()

    # udpate for mw 0.11 & 0.10.1
    if(!is.null(params)){
      ind <- .id %% length(params$x)
      if(ind == 0) ind <- length(params$x)
      
      if(length(mcYear) == 0){return(combineWidgets(.getLabelLanguage("Please select some mcYears", language)))}
      
      if(length(variable) == 0){return(combineWidgets(.getLabelLanguage("Please select some variables", language)))}
      
      if(length(elements) == 0){return(combineWidgets(.getLabelLanguage("Please select some elements", language)))}
      
      if(length(params[["x"]][[ind]]) == 0){return(combineWidgets(.getLabelLanguage("No data", language)))}
      
      if(is.null(params[["x"]][[ind]][[table]])){
        return(combineWidgets(
          paste0("Table ", table, " ", .getLabelLanguage("not exists in this study", language))
        ))
      }
      
      if(!secondAxis){
        variable2Axe <- NULL
      } else {
        aggregate <- "none"
      }
      
      
      widget <- params[["x"]][[ind]][[table]]$plotFun(mcYear, .id, variable, variable2Axe, elements, type, 
                                                      typeConfInt, confInt, 
                                                      dateRange, minValue, maxValue, aggregate, legend, 
                                                      highlight, stepPlot, drawPoints, main)
      
      controlWidgetSize(widget, language)
      
    } else {
      combineWidgets(.getLabelLanguage("No data for this selection", language))
    }
  },
  x = mwSharedValue({x}),
  
  # #Output
  #  outPutGraph = mwSharedValue({
  #    ls()
  # }),
  
  
  x_in = mwSharedValue({
    .giveListFormat(x)
  }),
  
  h5requestFiltering = mwSharedValue({h5requestFiltering}),
  
  # paramsH5 = mwSharedValue({
  #   .h5ParamList(X_I = x_in, xyCompare = xyCompare, h5requestFilter = h5requestFiltering)
  # }),
  
  H5request = mwGroup(
    label = .getLabelLanguage("H5request", language),
    timeSteph5 = mwSelect(
      {
        if(length(paramsH5) > 0){
          choices = paramsH5$timeStepS
          names(choices) <- sapply(choices, function(x) .getLabelLanguage(x, language))
          choices
        } else {
          NULL
        }
      }, 
      value =  if(.initial) {paramsH5$timeStepS[1]}else{NULL},
      label = .getLabelLanguage("timeStep", language), 
      multiple = FALSE, .display = !"timeSteph5" %in% hidden
    ),
    tables = mwSelect(
      {
        choices = paramsH5[["tabl"]]
        names(choices) <- sapply(choices, function(x) .getLabelLanguage(x, language))
        choices
      },
      value = {
        if(.initial) {paramsH5[["tabl"]][1]}else{NULL}
      }, 
      label = .getLabelLanguage("table", language), multiple = TRUE, 
      .display = !"tables" %in% hidden
    ),
    mcYearH5 = mwSelectize(
      choices = {
        ch <- c("Average" = "", paramsH5[["mcYearS"]])
        names(ch)[1] <- .getLabelLanguage("Average", language)
        ch
      },
      value = {
        if(.initial){paramsH5[["mcYearS"]][1]}else{NULL}
      },
      label = .getLabelLanguage("mcYears to be imported", language), 
      multiple = TRUE, options = list(maxItems = 4),
      .display = (!"mcYearH5" %in% hidden  & !meanYearH5)
    ),
    meanYearH5 = mwCheckbox(value = FALSE, 
                            label = .getLabelLanguage("Average mcYear", language),
                            .display = !"meanYearH5" %in% hidden),
    .display = {
      any(unlist(lapply(x_in, .isSimOpts))) & !"H5request" %in% hidden
    }),
  
  sharerequest = mwSharedValue({
    if(length(meanYearH5) > 0){
      if(meanYearH5){
        list(timeSteph5_l = timeSteph5, mcYearh_l = NULL, tables_l = tables)
      } else {
        list(timeSteph5_l = timeSteph5, mcYearh_l = mcYearH5, tables_l = tables)
      }
    } else {
      list(timeSteph5_l = timeSteph5, mcYearh_l = mcYearH5, tables_l = tables)
    }
  }),
  
  x_tranform = mwSharedValue({
    
    resXT <- .get_x_transform(x_in = x_in,
                              sharerequest = sharerequest,
                              refStudy = refStudy, 
                              h5requestFilter = paramsH5$h5requestFilter )
    resXT 
  }),
  
  table = mwSelect(
    {
      if(!is.null(params)){
        out <- as.character(.compareOperation(
          lapply(params$x, function(vv){
            unique(names(vv))
          }), xyCompare))
        if(length(out) > 0){
          names(out) <- sapply(out, function(x) .getLabelLanguage(x, language))
          out
        }else{"No Input"}
      }
    }, 
    value = {
      if(.initial) table
      else NULL
    }, .display = length(as.character(.compareOperation(
      lapply(params$x, function(vv){
        unique(names(vv))
      }), xyCompare))) > 1 & !"table" %in% hidden, 
    label = .getLabelLanguage("table", language)
  ),
  
  mcYear = mwSelect(
    choices = {
      # tmp <- c("average", if(!is.null(params)){
      #   as.character(.compareOperation(lapply(params$x, function(vv){
      #     unique(vv[[table]]$uniqueMcYears)
      #   }), xyCompare))})
      # names(tmp) <- sapply(tmp, function(x) .getLabelLanguage(x, language))
      # tmp
      
      # BP 2017
      allMcY <- .compareOperation(lapply(params$x, function(vv){
        unique(vv[[table]]$uniqueMcYears)
      }), xyCompare)
      names(allMcY) <- allMcY
      if(is.null(allMcY)){
        allMcY <- "average"
        names(allMcY) <- .getLabelLanguage("average", language)
      }
      allMcY
      
    },
    value = {
      # if(.initial) "average"
      allMcY <- .compareOperation(lapply(params$x, function(vv){
        unique(vv[[table]]$uniqueMcYears)
      }), xyCompare)
      names(allMcY) <- allMcY
      if(is.null(allMcY)){
        allMcY <- "average"
        names(allMcY) <- .getLabelLanguage("average", language)
      }
      allMcY
      if(.initial){
        if(mcYear %in% allMcY){
          mcYear
        } else {
          allMcY[1]
        }
      } else {
        allMcY[1]
      }
    }, multiple = TRUE, 
    label = .getLabelLanguage("mcYear to be displayed", language), 
    .display = !"mcYear" %in% hidden
  ),
  
  variable = mwSelect(
    choices = {
      if(!is.null(params)){
        out <- as.character(.compareOperation(lapply(params$x, function(vv){
          unique(vv[[table]]$valueCols)
        }), xyCompare))
        if(length(out) > 0){out} else {"No Input"}
      }
    },
    value = {
      if(.initial){
        if(is.null(variable)){
          as.character(.compareOperation(lapply(params$x, function(vv){
            unique(vv[[table]]$valueCols)
          }), xyCompare))[1]
        } else {
          variable
        }
      } else {
        # NULL
        as.character(.compareOperation(lapply(params$x, function(vv){
          unique(vv[[table]]$valueCols)
        }), xyCompare))[1]
      }
    }, multiple = TRUE, 
    label = .getLabelLanguage("variable", language),
    .display = !"variable" %in% hidden
  ),
  
  secondAxis = mwCheckbox(secondAxis, label = .getLabelLanguage("secondAxis", language), 
                          .display = !"secondAxis" %in% hidden),
  variable2Axe = mwSelect(label = .getLabelLanguage("Variables 2nd axis", language),
                          choices = {
                            if(!is.null(params)){
                              out <- as.character(.compareOperation(lapply(params$x, function(vv){
                                unique(vv[[table]]$valueCols)
                              }), xyCompare))
                              out <- out[!out%in%variable]
                              if(length(out) > 0){out} else {"No Input"}
                            }
                          },
                          value = {
                            if(.initial) variable2Axe
                            else NULL
                          }, multiple = TRUE, .display = secondAxis & !"variable2Axe" %in% hidden
  ),
  type = mwSelect(
    choices = {
      if (timeStepdataload == "annual") "barplot"
      else if (timeStepdataload %in% c("hourly", "daily")) typeChoices
      else setdiff(typeChoices, "heatmap")
    },
    value = {
      if(.initial) type
      else NULL
    }, 
    .display = timeStepdataload != "annual" & !"type" %in% hidden, 
    label = .getLabelLanguage("type", language)
  ),
  typeConfInt = mwCheckbox(value = FALSE, 
                           label = .getLabelLanguage("confidence interval", language), 
                           .display = length(mcYear) > 1 & !"typeConfInt" %in% hidden & type %in% c("barplot", "ts", "monotone")),
  confInt = mwSlider(0, 1, confInt, step = 0.01, 
                     label = "",
                     .display = length(mcYear) > 1 & !"typeConfInt" %in% hidden & type %in% c("barplot", "ts", "monotone") & typeConfInt & !"confInt" %in% hidden
  ),
  dateRange = mwDateRange(value = {
    if(.initial){
      res <- NULL
      if(!is.null(params) & ! is.null(table)){
        res <- c(.dateRangeJoin(params = params, xyCompare = xyCompare, "min", tabl = table),
                 .dateRangeJoin(params = params, xyCompare = xyCompare, "max", tabl = table))
        if(any(is.infinite(c(res))))
        {res <- NULL}
      }
      ##Lock 7 days for hourly data
      if(!is.null(params$x[[1]][[table]]$timeStep)){
        if(params$x[[1]][[table]]$timeStep == "hourly"){
          if(params$x[[1]][[table]]$dateRange[2] - params$x[[1]][[table]]$dateRange[1]>7){
            res[1] <- params$x[[1]][[table]]$dateRange[2] - 7
          }
        }
      }
      res
    }else{NULL}
  }, 
  min = {      
    if(!is.null(params) & ! is.null(table)){
      R <- .dateRangeJoin(params = params, xyCompare = xyCompare, "min", tabl = table)
      if(is.infinite(R)){NULL}else{R}
    }
  }, 
  max = {      
    if(!is.null(params) & ! is.null(table)){
      R <- .dateRangeJoin(params = params, xyCompare = xyCompare, "max", tabl = table)
      if(is.infinite(R)){NULL}else{R}
    }
  },
  language = eval(parse(text = "language")),
  # format = "dd MM",
  separator = " : ",
  .display = timeStepdataload != "annual" & !"dateRange" %in% hidden, 
  label = .getLabelLanguage("dateRange", language)
  ),
  minValue = mwNumeric(minValue, label = .getLabelLanguage("min value", language), 
                       .display = type %in% c("density", "cdf") & !"minValue" %in% hidden
  ),
  
  maxValue = mwNumeric(maxValue, label = .getLabelLanguage("max value", language), 
                       .display = type %in% c("density", "cdf") & !"maxValue" %in% hidden
  ),
  
  elements = mwSelect(
    choices = {
      choix <- c(if(!is.null(params)){
        as.character(.compareOperation(lapply(params$x, function(vv){
          unique(vv[[table]]$uniqueElem)
        }), xyCompare))
      })
      choix
    },
    value = {
      if(.initial) {
        if(is.null(elements)){
          
          if(!is.null(params)){
            as.character(.compareOperation(lapply(params$x, function(vv){
              unique(vv[[table]]$uniqueElem)
            }), xyCompare))[1]
          } else {
            NULL
          }
        }else {
          elements
        }
      } else {
        NULL
      }
    }, 
    multiple = TRUE, 
    label = .getLabelLanguage("elements", language), 
    .display = !"elements" %in% hidden
  ),
  
  aggregate = mwSelect({
    tmp <- c("none", "mean", "sum", "mean by variable", "sum by variable")
    names(tmp) <- c(.getLabelLanguage("none", language), 
                    .getLabelLanguage("mean", language),
                    .getLabelLanguage("sum", language),
                    .getLabelLanguage("mean by variable", language),
                    .getLabelLanguage("sum by variable", language))
    tmp
  }, value ={
    if(.initial) aggregate
    else NULL
  }, .display = !secondAxis & !"aggregate" %in% hidden, 
  label = .getLabelLanguage("aggregate", language)
  ),
  
  legend = mwCheckbox(legend, .display = type %in% c("ts", "density", "cdf") & !"legend" %in% hidden, 
                      label = .getLabelLanguage("legend", language)),
  highlight = mwCheckbox(highlight, label = .getLabelLanguage("highlight", language), 
                         .display = !"highlight" %in% hidden),
  stepPlot = mwCheckbox(stepPlot, label = .getLabelLanguage("stepPlot", language), 
                        .display = !"stepPlot" %in% hidden),
  drawPoints = mwCheckbox(drawPoints, label =.getLabelLanguage("drawPoints", language), 
                          .display = !"drawPoints" %in% hidden),
  timeStepdataload = mwSharedValue({
    attributes(x_tranform[[1]])$timeStep
  }),
  
  main = mwText(main, label = .getLabelLanguage("title", language), 
                .display = !"main" %in% hidden),
  
  params = mwSharedValue({
    #.transformDataForComp(x_tranform, compare, compareOpts, processFun = processFun, 
    #                      elements = init_elements, dateRange = init_dateRange)
    .getDataForComp(x = x_tranform, y = NULL, compare,
                    compareOpts = compareOptions, 
                    processFun = processFun,
                    elements = init_elements,
                    dateRange = init_dateRange)
    
  }),
  
  .compare = {
    compare
  },
  .compareOpts = {
    compareOptions
  },
  ...
  )
}


#' @export
#' @rdname tsPlot
#' @method plot antaresData
plot.antaresData <- tsPlot

#' @export
#' @rdname tsPlot
#' @method plot simOptions
plot.simOptions <- tsPlot

#' @export
#' @rdname tsPlot
#' @method plot list
plot.list <- tsPlot

