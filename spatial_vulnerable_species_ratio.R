if (!require("pacman")) install.packages("pacman")
if (!require("rnaturalearthdata")) install.packages("rnaturalearthdata")

pacman::p_load(shiny, ggplot2, rnaturalearth, sf, terra,
               tidyterra, ggalt, ggspatial, ggpmisc, marmap, 
               ggrepel, sjmisc, DT)

 ui = fluidPage(
  titlePanel("Spatial fishing risk mapper"),
  
  sidebarLayout(
    sidebarPanel(
      h4("1. Upload Datasets"),
      fileInput("vuln_file", "Upload Vulnerability Class CSV",
                accept = c(".csv")),
      fileInput("species_file", "Upload Species Data CSV",
                accept = c(".csv")),
      
      hr(),
      
      h4("2. Select Characteristics"),
      selectInput("international", "International Study Area?",
                  choices = c("no", "yes"),
                  selected = "no"),
      
      conditionalPanel(
        condition = "input.international == 'no'",
        textInput("country", "Country Name (in English)", 
                  value = "Brazil")
      ),
      
      numericInput("bathy_res", "Bathymetry Resolution (minutes)",
                   value = 1, min = 0.1, max = 10, step = 0.1),
      
      numericInput("max_depth", "Maximum Depth",
                   value = -150, step = 10),
      
      numericInput("min_depth", "Minimum Depth",
                   value = 0, step = 10),
      
      textInput("thresholds", "Thresholds (comma-separated)",
                value = "0, 0.25, 0.5, 1"),
      
      numericInput("dpi", "Map DPI",
                   value = 600, min = 72, max = 1200, step = 50),
      
      hr(),
      
      h4("3. Run Analysis"),
      actionButton("run_analysis", "Generate Map & Results",
                   class = "btn-primary btn-lg btn-block")
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Map Visualization",
                 br(),
                 plotOutput("vsr_map", height = "600px"),
                 br(),
                 conditionalPanel(
                   condition = "output.has_time",
                   plotOutput("vsr_time_map", height = "600px")
                 ),
                 br(),
                 downloadButton("download_map", "Download Map (PNG)")
        ),
        
        tabPanel("Results Table",
                 br(),
                 DTOutput("results_table"),
                 br(),
                 downloadButton("download_csv", "Download CSV")
        )
      )
    )
  )
)

server <- function(input, output, session) {
  
  # Reactive values to store results
  results <- reactiveValues(
    vsr_map = NULL,
    vsr_time_map = NULL,
    vsr_data = NULL,
    has_time = FALSE
  )
  
  # Run analysis when button is clicked
  observeEvent(input$run_analysis, {
    req(input$vuln_file, input$species_file)
    
    withProgress(message = 'Processing data...', value = 0, {
      
      # Read uploaded files
      incProgress(0.1, detail = "Reading files...")
      vuln_df = read.csv(input$vuln_file$datapath)
      species_data = read.csv(input$species_file$datapath)
      
      # Parse thresholds
      my_thresholds = as.numeric(unlist(strsplit(input$thresholds, ",")))
      
      # Get bathymetry data
      incProgress(0.2, detail = "Fetching bathymetry data...")
      lon1 = min(species_data$longitude) + min(species_data$longitude) * 0.01 
      lon2 = max(species_data$longitude) - max(species_data$longitude) * 0.01
      lat1 = min(species_data$latitude) + min(species_data$latitude) * 0.01
      lat2 = max(species_data$latitude) - max(species_data$latitude) * 0.01
      
      bathy = tryCatch({
        getNOAA.bathy(lon1 = lon1, lon2 = lon2, lat1 = lat1, lat2 = lat2,
                      res = input$bathy_res, keep = FALSE) %>%
          as.xyz() %>%
          subset(V3 > input$max_depth & V3 < input$min_depth) %>%
          rasterFromXYZ() %>%
          rast()
      }, error = function(e) NULL)
      
      # Calculate vulnerable species ratio
      incProgress(0.4, detail = "Calculating VSR...")
      vul_map = data.frame(setNames(vuln_df$vul_category, vuln_df$species))
      
      vulclass_df = species_data[, -c(1:3)]
      colnames(vulclass_df) = vul_map$setNames.vuln_df.vul_category..vuln_df.species.
      
      vulclass_df = as.data.frame(sapply(split.default(vulclass_df, 
                                                       names(vulclass_df)), 
                                         rowSums))
      vulclass_df[is.na(vulclass_df)] = 0
      
      if('Moderate' %in% colnames(vulclass_df)) {
        vsr = ((vulclass_df$Moderate + vulclass_df$High) + 1) / (rowSums(vulclass_df) + 1)
      } else {
        vsr = ((vulclass_df$High) + 1) / (rowSums(vulclass_df) + 1)
      }
      
      vsr_cut = cut(vsr, breaks = my_thresholds)
      
      # Get geographic shapefile
      incProgress(0.6, detail = "Loading geographic data...")
      if (input$international == 'no') {
        geo_shp = ne_states(input$country, returnclass = 'sf')
      } else {
        geo_shp = ne_countries(returnclass = 'sf')
      }
      
      # Create map
      incProgress(0.8, detail = "Generating map...")
      vsr_map_plot = ggplot(species_data) +
        geom_encircle(data = species_data, 
                      aes(x = longitude, y = latitude, fill = vsr_cut),
                      s_shape = 1, alpha = 0.4, spread = 0.0001, 
                      color = 'transparent') +
        geom_sf(data = geo_shp) +
        coord_sf(xlim = c(lon1, lon2), ylim = c(lat1, lat2)) +
        labs(x = '', y = '', fill = 'Vulnerable Species Ratio') +
        theme_bw() +
        scale_fill_manual(values = c('forestgreen', 'yellow', 'red3')) +
        theme(legend.position = 'bottom',
              axis.text.x = element_text(angle = 60, vjust = .6, color = 'black'),
              axis.text.y = element_text(angle = 60, hjust = .6, color = 'black')) +
        guides(fill = guide_colorsteps(barheight = 0.5, barwidth = 10,
                                       title.position = 'bottom', show.limits = TRUE))
      
      if (!is.null(bathy)) {
        vsr_map_plot = vsr_map_plot +
          geom_spatraster_contour_text(data = bathy)
      }
      
      results$vsr_map = vsr_map_plot
      
      # Check for time column and create time-based map
      results$has_time = !all_na(species_data$time)
      
      if (results$has_time) {
        results$vsr_time_map = vsr_map_plot + facet_wrap(~time)
        results$vsr_data = data.frame(
          time = species_data$time,
          latitude = species_data$latitude,
          longitude = species_data$longitude,
          vulnerable_species_ratio = vsr
        )
      } else {
        results$vsr_time_map = NULL
        results$vsr_data = data.frame(
          latitude = species_data$latitude,
          longitude = species_data$longitude,
          vulnerable_species_ratio = vsr
        )
      }
      
      incProgress(1, detail = "Done!")
    })
    
    showNotification("Analysis complete!", type = "message")
  })
  
  # Render main map
  output$vsr_map <- renderPlot({
    req(results$vsr_map)
    results$vsr_map
  })
  
  # Render time-based map
  output$vsr_time_map <- renderPlot({
    req(results$vsr_time_map)
    results$vsr_time_map
  })
  
  # Check if time column exists
  output$has_time <- reactive({
    results$has_time
  })
  outputOptions(output, "has_time", suspendWhenHidden = FALSE)
  
  # Render results table
  output$results_table <- renderDT({
    req(results$vsr_data)
    datatable(results$vsr_data, 
              options = list(pageLength = 25, scrollX = TRUE),
              rownames = FALSE)
  })
  
  # Download map
  output$download_map <- downloadHandler(
    filename = function() {
      paste0("vsr_map_", Sys.Date(), ".png")
    },
    content = function(file) {
      ggsave(file, plot = results$vsr_map, 
             width = 25/4, height = 25/4, dpi = input$dpi)
    }
  )
  
  # Download CSV
  output$download_csv <- downloadHandler(
    filename = function() {
      paste0("vsr_results_", Sys.Date(), ".csv")
    },
    content = function(file) {
      write.csv(results$vsr_data, file, row.names = FALSE)
    }
  )
}

shinyApp(ui = ui, server = server)