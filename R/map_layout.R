# Copyright © 2016 RTE Réseau de transport d’électricité

#' Place areas of a study on a map
#' 
#' This function launches an interactive application that let the user place 
#' areas of a study on a map. the GPS coordinates of the areas are then returned
#' and can be used in functions. This function should be used only once per 
#' study. The result should then be saved in an external file and be reused.
#' 
#' @param layout
#'   object returned by function [antaresRead::readLayout()]
#' @param what
#'   Either "areas" or "districts". Indicates what type of object to place
#'   on the map.
#' @param map
#'   An optional [sp::SpatialPolygons()] or 
#'   [sp::SpatialPolygonsDataFrame()] object. See [spMaps::getSpMaps()]
#'   
#' @param map_builder \code{logical} Add inputs for build custom map ? Defaut to TRUE.
#' 
#' @details 
#' With \code{map_builder} option, you can build a quiet custom map using \code{spMaps} package. 
#' This package help you to build [sp::SpatialPolygons()] on Europe. 
#' Moreover, you can use two options in the module : 
#' 
#' \itemize{
#'    \item {"Merge countries" : Some countries like UK or Belgium are firstly rendered in multiple and diffrent area. 
#'    You can so choose to finally use this countries as one single area on the map}
#'    \item {"Merge states" : If you need states details but not having one area per state, the map will be incomplete 
#'    for some countries, plotting only states with area. So you can choose to aggregate the states of the countries.
#'    This is done using a nearest states algorithm. The result is available only after layout validation.}
#'  }
#' @return 
#' An object of class \code{mapLayout}.
#' 
#' @examples 
#' \dontrun{
#' # Read the coordinates of the areas in the Antares interface, then convert it
#' # in a map layout.
#' layout <- readLayout()
#' ml <- mapLayout(layout)
#' 
#' # visualize mapLayout
#' plotMapLayout(ml)
#' 
#' # Save the result for future use
#' save(ml, file = "ml.rda")
#' 
#' }
#' 
#' @export
#' @import spMaps
#'
#' @seealso [plotMapLayout()]
mapLayout <- function(layout, what = c("areas", "districts"), map = getSpMaps(), map_builder = TRUE) {
  
  what <- match.arg(what)
  
  ui <- fluidPage(
    changeCoordsUI("ml", map_builder = map_builder)
  )
  
  server <- function(input, output, session) {
    callModule(changeCoordsServer, "ml", reactive(layout), what = reactive(what), 
               map = reactive(map), map_builder = map_builder, stopApp = TRUE)
  }
  
  mapCoords <- shiny::runApp(shiny::shinyApp(ui = ui, server = server))
  
  mapCoords
}

#' Visualize mapLayout output.
#' 
#' @param mapLayout
#'   object returned by function [mapLayout()]
#'   
#' @examples 
#' 
#' \dontrun{
#' # Read the coordinates of the areas in the Antares interface, then convert it
#' # in a map layout.
#' layout <- readLayout()
#' ml <- mapLayout(layout)
#' 
#' # visualize mapLayout
#' plotMapLayout(ml)
#' 
#' }
#' 
#' @export
#' 
#' @seealso [mapLayout()]
plotMapLayout <- function(mapLayout){
  
  if (!is.null(mapLayout$all_coords)){
    coords <- data.frame(mapLayout$all_coords)
    colnames(coords) <- gsub("^x$", "lon", colnames(coords))
    colnames(coords) <- gsub("^y$", "lat", colnames(coords))
    coords$info <- coords$area
  } else if (is.null(mapLayout$all_coords)){
    coords <- data.frame(mapLayout$coords)
    colnames(coords) <- gsub("^x$", "lon", colnames(coords))
    colnames(coords) <- gsub("^y$", "lat", colnames(coords))
    coords$info <- coords$area
  } else {
    stop("No coordinates found in layout")
  }
  
  leafletDragPoints(coords, map = mapLayout$map, init = TRUE, draggable = FALSE)
}

# changeCoords Module UI function
changeCoordsUI <- function(id, map_builder = TRUE) {
  # Create a namespace function using the provided id
  ns <- NS(id)
  
  ref_map_table <- spMaps::getEuropeReferenceTable()
  choices_map <- c("all", ref_map_table$code)
  names(choices_map) <- c("all", ref_map_table$name)
  
  tagList(
    fluidRow(
      column(3, 
             if (map_builder){
               selectInput(ns("ml_countries"), "Countries : ", width = "100%",
                           choices = choices_map, selected = "all", multiple = TRUE)
             }
      ),
      column(3, 
             if (map_builder){
               selectInput(ns("ml_states"), "States : ", width = "100%",
                           choices = choices_map, selected = NULL, multiple = TRUE)
             }
      ),   
      column(2, 
             if (map_builder){
               div(br(), checkboxInput(ns("merge_cty"), "Merge countries ?", TRUE), align = "center")
             }
      ), 
      column(2, 
             if (map_builder){
               div(br(), checkboxInput(ns("merge_ste"), "Merge states ?", TRUE), align = "center")
             }
      ), 
      column(2, 
             if (map_builder){
               div(br(), actionButton(ns("set_map_ml"), "Set map"), align = "center")
             }
      )
    ),
    fluidRow(
      column(2, 
             div(br(), actionButton(ns("reset_ml"), "Re-Init layout"), align = "center")
             
      ),
      column(width = 8, div(h3(textOutput(ns("title_layout"))), align = "center")),
      column(2, 
             conditionalPanel(
               condition = paste0("output['", ns("control_state"), "'] >= 2"),
               div(br(), actionButton(ns("done"), "Done"), align = "center")
             )
      )
    ), 
    
    hr(), 
    
    fillRow(
      flex = c(NA, 1),
      tags$div(
        style = "width:200px;",
        tags$p(textOutput(ns("order"))),
        htmlOutput(ns("info")),
        conditionalPanel(
          condition = paste0("output['", ns("control_state"), "'] < 2"),
          imageOutput(ns("preview"), height = "150px"),
          tags$p(),
          actionButton(ns("state"), "Next")
        )
      ),
      leafletDragPointsOutput(ns("map"), height = "700px")
    )
  )
}

# changeCoords Module SERVER function
#' @import sp
#' @import sf
changeCoordsServer <- function(input, output, session, 
                               layout, what = reactive("areas"), 
                               map = reactive(NULL), map_builder = TRUE, 
                               language = reactive("en"), stopApp = FALSE){
  
  ns <- session$ns
  
  lfDragPoints <- reactiveValues(map = NULL, init = FALSE)
  
  current_state <- reactiveValues(state = -1)
  output$control_state <- reactive({
    current_state$state
  })
  
  observe({
    updateSelectInput(session, "ml_countries", 
                      label = paste0(.getLabelLanguage("Countries", language()), " : "))
    updateSelectInput(session, "ml_states", 
                      label = paste0(.getLabelLanguage("States", language()), " : "))
    
    updateCheckboxInput(session, "merge_cty", .getLabelLanguage("Merge countries ?", language()))
    updateCheckboxInput(session, "merge_ste", .getLabelLanguage("Merge states ?", language()))
    
    updateActionButton(session, "state", label = .getLabelLanguage("Next", language()))
    updateActionButton(session, "done", label = .getLabelLanguage("Done", language()))
    updateActionButton(session, "reset_ml", label = .getLabelLanguage("Re-Init layout", language()))
    updateActionButton(session, "set_map_ml", label = .getLabelLanguage("Set map", language()))
    
  })
  
  output$title_layout <- renderText({
    .getLabelLanguage("Map Layout", language())
  })
  
  outputOptions(output, "control_state", suspendWhenHidden = FALSE)
  
  current_map <- reactive({
    if (!map_builder){
      checkSlotId(map())
    } else {
      if (!is.null(map()) & input$set_map_ml == 0){
        checkSlotId(map())
      } else {
        checkSlotId(getSpMaps(countries = isolate(input$ml_countries), states = isolate(input$ml_states), 
                  mergeCountry = isolate(input$merge_cty)))
      }
    }
  })
  
  data <- reactive({
    input$reset_ml
    if (!is.null(layout())){
      if (what() == "areas") {
        coords <- copy(layout()$areas)
        info <- coords$area
        links <- copy(layout()$links)
        if(is.null(links)) links <- data.table()
      } else {
        coords <- copy(layout()$districts)
        info <- coords$district
        links <- copy(layout()$districtLinks)
        if(is.null(links)) links <- data.table()
      }
      
      links$x0 <- as.numeric(links$x0)
      links$x1 <- as.numeric(links$x1)
      links$y0 <- as.numeric(links$y0)
      links$y1 <- as.numeric(links$y1)
      
      current_state$state <- 0
      
      list(coords = coords, info = info, links = links)
    } else {
      NULL
    }
  })
  
  data_points <- reactiveValues()
  
  observe({
    if (!is.null(data())){
      cur_points <- data.frame(lon = data()$coords$x, lat = data()$coords$y, 
                               oldLon = data()$coords$x, oldLat = data()$coords$y,
                               color = data()$coords$color, info = as.character(data()$info), stringsAsFactors = FALSE)
      isolate({
        data_points$points <- cur_points
        
        avgCoord <- rowMeans(data_points$points[, c("lon", "lat")])
        pt1 <- which.min(avgCoord)
        pt2 <- which.max(avgCoord)
        
        data_points$points$lon[pt1] <- data_points$points$lat[pt1] <- 0
        
        data_points$pt1 <- pt1
        data_points$pt2 <- pt2
        
      })
    }
  })
  
  renderPreview <- function(pt) {
    renderPlot({
      points <- isolate(data_points$points)
      if (!is.null(points)){
        col <- rep("#cccccc", nrow(points))
        col[pt] <- "red"
        cex <- rep(1, nrow(points))
        cex[pt] <- 2
        par (mar = rep(0.1, 4))
        graphics::plot.default(points$oldLon, points$oldLat, bty = "n", xaxt = "n", yaxt = "n",
                               xlab = "", ylab = "", main = "", col = col, asp = 1, pch = 19, cex = cex)
      }
    })
  }
  
  observeEvent(input$state, {
    if (input$state > 0){
      current_state$state <- current_state$state + 1
    }
  })
  
  observeEvent(input$reset_ml, {
    if (input$state >= 0){
      current_state$state <- 0
    }
  })
  
  observe({
    if (current_state$state == 0) {
      lfDragPoints$map <- leafletDragPoints(data_points$points[data_points$pt1, ], isolate(current_map()), init = TRUE)
    }
  })
  
  observe({
    if (current_state$state == 1) {
      lfDragPoints$map <- leafletDragPoints(data_points$points[data_points$pt2, ])
    }
  })
  
  observe({
    if (current_state$state == 2) {
      lfDragPoints$map <- leafletDragPoints(data_points$points[-c(data_points$pt1, data_points$pt2), ])
    }
  })
  
  observe({
    if (!is.null(input$map_init)){
      if (input$map_init){
        lfDragPoints$map <- leafletDragPoints(NULL, current_map(), reset_map = TRUE)
      }
    }
  })
  
  # Initialize outputs
  output$map <- renderLeafletDragPoints({lfDragPoints$map})
  
  coords <- reactive({
    coords <- matrix(input[[paste0("map", "_coords")]], ncol = 2, byrow = TRUE)
    colnames(coords) <- c("lat", "lon")
    as.data.frame(coords)
  })
  
  observe({
    if (current_state$state == 0) {
      output$order <- renderText({
        .getLabelLanguage("Please place the following point on the map", language())
      })
      
      output$info <- renderUI(HTML(data_points$points$info[data_points$pt1]))
      output$preview <- renderPreview(data_points$pt1)
    } else if (current_state$state == 1) {
      isolate({
        data_points$points$lat[data_points$pt2] <- input[[paste0("map", "_mapcenter")]]$lat
        data_points$points$lon[data_points$pt2] <- input[[paste0("map", "_mapcenter")]]$lng
        output$info <- renderUI(HTML(data_points$points$info[data_points$pt2]))
        output$preview <- renderPreview(data_points$pt2)
      })
    } else if (current_state$state == 2) {
      isolate({
        data_points$points <- .changeCoordinates(data_points$points, coords(), c(data_points$pt1, data_points$pt2))
        output$order <- renderText({
          .getLabelLanguage("Drag the markers on the map to adjust coordinates then click the 'Done' button", language())
        })
        
        output$info <- renderUI(HTML( 
          paste0("<p>", 
                 .getLabelLanguage("You can click on a marker to display information", language()), 
                 "</p>"))
        )
        
      })
    }
  })
  
  # get coord
  cur_coords <- reactiveValues(data = NULL)
  
  # When the Done button is clicked, return a value
  observeEvent(input$done, {
    coords <- sp::SpatialPoints(coords()[, c("lon", "lat")],
                                proj4string = sp::CRS("+proj=longlat +datum=WGS84"))
    
    # special with only one area...
    if(nrow(data()$coords) == 1){
      coords <- coords[1, ]
    } 
    
    map <- current_map()
    
    if (!is.null(map)) {
      map <- sp::spTransform(map, sp::CRS("+proj=longlat +datum=WGS84"))
      map$geoAreaId <- 1:length(map)
      coords$geoAreaId <- sp::over(coords, map)$geoAreaId
    }
    
    # Put coords in right order
    if(nrow(data()$coords) > 1){
      ord <- order(c(data_points$pt1, data_points$pt2, (1:length(coords))[-c(data_points$pt1, data_points$pt2)]))
      mapCoords <- coords[ord, ]
    } else {
      mapCoords <- coords
    }
    
    final_coords <- data()$coords
    final_links <- data()$links
    
    final_coords$x <- sp::coordinates(mapCoords)[, 1]
    final_coords$y <- sp::coordinates(mapCoords)[, 2]
    
    if (what() == "areas") {
      if(!is.null(final_links) && nrow(final_links) > 0){
        final_links[final_coords, `:=`(x0 = x, y0 = y), on = c(from = "area")]
        final_links[final_coords, `:=`(x1 = x, y1 = y), on = c(to = "area")]
      }
    } else {
      if(!is.null(final_links) && nrow(final_links) > 0){
        final_links[final_coords, `:=`(x0 = x, y0 = y), on = c(fromDistrict = "district")]
        final_links[final_coords, `:=`(x1 = x, y1 = y), on = c(toDistrict = "district")]
      }
    }
    
    if (!is.null(map)) {
      final_coords$geoAreaId <- mapCoords$geoAreaId
      final_coords_map <- final_coords[!is.na(final_coords$geoAreaId), ]
      if (!isolate(input$merge_ste)){
        map <- map[final_coords_map$geoAreaId, ]
      } else {
        if (all(c("name", "code") %in% names(map))){
          keep_code <- unique(map$code[final_coords_map$geoAreaId])
          # subset on countries
          tmp_map <- map[map$code %in% keep_code, ]
          
          if (nrow(tmp_map) > 0){
            # set unlink states
            tmp_map$geoAreaId[!tmp_map$geoAreaId %in% final_coords_map$geoAreaId] <- NA
            
            ind_na <- which(is.na(tmp_map$geoAreaId))
            if (length(ind_na) > 0){
              # have to find nearestArea...
              treat_cty <- unique(tmp_map$code[ind_na])
              
              for (cty in treat_cty){
                ind_cty <- which(tmp_map$code %in% cty)
                ind_miss <- which(tmp_map$code %in% cty & is.na(tmp_map$geoAreaId))
                areas <- coords[coords$geoAreaId %in% tmp_map$geoAreaId[ind_cty], ]
                if (nrow(areas) > 0){
                  tmp_sf <- st_as_sf(tmp_map[ind_miss, ])
                  areas_sf <- st_as_sf(areas)
                  dist_matrix <- st_distance(tmp_sf, areas_sf)
                  areas_min <- suppressWarnings(apply(dist_matrix, 1, which.min))
                  tmp_map$geoAreaId[ind_miss] <- areas$geoAreaId[areas_min]
                }
              }
              tmp_sf <- st_cast(tmp_map, "MULTIPOLYGON")  # Cast to multipolygon if needed
              tmp_sf <- st_cast(tmp_sf, "GEOMETRY")  # Remove unused geometry types
              tmp_sf <- st_combine(tmp_sf)  # Combine features with the same geoAreaId
              map <- tmp_sf[match(final_coords_map$geoAreaId, tmp_map$geoAreaId), ]
            } else {
              map <- map[match(final_coords_map$geoAreaId, map$geoAreaId), ]
            }
          }else {
            map <- map[match(final_coords_map$geoAreaId, map$geoAreaId), ]
          }
        } else {
          map <- map[match(final_coords_map$geoAreaId, map$geoAreaId), ]
        }
        # remove if multiple same polygon. Needed other change...
        # map <- map[!duplicated(map$geoAreaId), ]
      }
      
      res <- list(coords = final_coords_map, links = final_links, map = map, all_coords = final_coords)
      
    } else {
      res <- list(coords = final_coords, links = final_links, map = map, all_coords = final_coords)
    }
    
    class(res) <- "mapLayout"
    attr(res, "type") <- what()
    
    cur_coords$data <- res
    
    if (stopApp){
      stopApp(res)
    }
  })
  
  return(reactive(cur_coords$data))
}

.changeCoordinates <- function(points, coords, pts = 1:nrow(points)) {
  coords$oldLon <- points$oldLon[pts]
  regLon <- lm(lon ~ oldLon, data = coords)
  points$lon <- predict(regLon, newdata = points)
  
  coords$oldLat <- points$oldLat[pts]
  regLat <- lm(lat ~ oldLat, data = coords)
  points$lat <- predict(regLat, newdata = points)
  
  points$oldLon <- points$oldLat <- NULL
  
  points
}

#' Plot method for map layout
#' 
#' This method can be used to visualize the network of an antares study.
#' It generates an interactive map with a visual representaiton of a
#' map layout created with function [mapLayout()]. 
#' 
#' @param x
#'   Object created with function [mapLayout()]
#' @param colAreas
#'   Vector of colors for areas. By default, the colors used in the Antares
#'   software are used.
#' @param dataAreas
#'   A numeric vector or a numeric matrix that is passed to function
#'   \code{link[addMinicharts]}. A single vector will produce circles with
#'   different radius. A matrix will produce bar charts or pie charts or 
#'   polar charts, depending on the value of \code{areaChartType}
#' @param opacityArea Opacity of areas. It has to be a numeric vector with values
#'   between 0 and 1.
#' @param areaMaxSize Maximal width in pixels of the symbols that represent 
#'   areas on the map.
#' @param areaChartType Type of chart to use to represent areas.
#' @param labelArea Character vector containing labels to display inside areas.
#' @param colLinks
#'   Vector of colors for links.
#' @param sizeLinks
#'   Line width of the links, in pixels.
#' @param opacityLinks Opacity of the links. It has to be a numeric vector with values
#'   between 0 and 1. 
#' @param dirLinks
#'   Single value or vector indicating the direction of the link. Possible values
#'   are 0, -1 and 1. If it equals 0, then links are repsented by a simple line. 
#'   If it is equal to 1 or -1 it is represented by a line with an arrow pointing
#'   respectively the destination and the origin of the link. 
#' @param areas
#'   Should areas be drawn on the map ?
#' @param links
#'   Should links be drawn on the map ?
#' @param ...
#'   Currently unused.
#' @inheritParams prodStack
#' @inheritParams plotMapOptions
#'   
#' @return 
#'   The function generates an \code{htmlwidget} of class \code{leaflet}. It can
#'   be stored in a variable and modified with package 
#'   [leaflet::leaflet()]
#'   
#' @method plot mapLayout
#'    
#' @examples 
#' \dontrun{
#' # Read the coordinates of the areas in the Antares interface, then convert it
#' # in a map layout.
#' layout <- readLayout()
#' ml <- mapLayout(layout)
#' 
#' # Save the result for future use
#' save(ml, file = "ml.rda")
#' 
#' # Plot the network on an interactive map
#' plot(ml)
#' 
#' # change style
#' plot(ml, colAreas = gray(0.5), colLinks = "orange")
#' 
#' # Use polar area charts to represent multiple values for each area.
#' nareas <- nrow(ml$coords)
#' fakeData <- matrix(runif(nareas * 3), ncol = 3)
#' plot(ml, sizeAreas = fakeData)
#' 
#' # Store the result in a variable to change it with functions from leaflet 
#' # package
#' library(leaflet)
#' 
#' center <- c(mean(ml$coords$x), mean(ml$coords$y))
#' 
#' p <- plot(ml)
#' p %>% 
#'   addCircleMarker(center[1], center[2], color = "red", 
#'                   popup = "I'm the center !")
#' }
#' 
#' @export
plot.mapLayout <- function(x, colAreas =  x$coords$color, dataAreas = 1,
                           opacityArea = 1, areaMaxSize = 30, areaMaxHeight = 50,
                           areaChartType = c("auto", "bar", "pie", "polar-area", "polar-radius"), 
                           labelArea = NULL, labelMinSize = 8, labelMaxSize = 8,
                           colLinks = "#CCCCCC", sizeLinks = 3, 
                           opacityLinks = 1, dirLinks = 0, 
                           links = TRUE, areas = TRUE, tilesURL = defaultTilesURL(),
                           preprocess = function(map) {map},
                           width = NULL, height = NULL, ...) {
  
  areaChartType <- match.arg(areaChartType)
  
  map <- leaflet(width = width, height = height, padding = 10) %>% addTiles(tilesURL) 
  
  # Add Polygons
  if (areas & !is.null(x$map)) {
    map <- addPolygons(map, data = x$map, layerId = x$coords$area, fillColor = colAreas, weight = 1,
                       fillOpacity = 1, color = "#333")
  }
  
  # Add custom elements
  if (is.function(preprocess)){
    map <- preprocess(map)
  }
  
  # Add links
  if (links) {
    map <- addFlows(map, x$links$x0, x$links$y0, x$links$x1, x$links$y1, dir = dirLinks,
                    flow = abs(sizeLinks), opacity = opacityLinks, maxFlow = 1, maxThickness = 1,
                    color = colLinks, layerId = x$links$link)
  }
  
  # Add areas
  if (areas) {
    
    areaChartType <- match.arg(areaChartType)
    
    # fix bug if set map wihout any intersection with areas...!
    map <- tryCatch(addMinicharts(map, lng = x$coords$x, lat = x$coords$y, 
                                  chartdata = dataAreas, fillColor = colAreas,
                                  showLabels = !is.null(labelArea),
                                  labelText = labelArea,
                                  width = areaMaxSize,
                                  height = areaMaxHeight,
                                  layerId = x$coords$area, 
                                  opacity = opacityArea,
                                  labelMinSize = labelMinSize,
                                  labelMaxSize = labelMaxSize), error = function(e) map)
    
  }
  
  # Add shadows to elements
  map %>% addShadows()
}
