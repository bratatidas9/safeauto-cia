library(shiny)
library(DT)
library(plotly)
require(googleVis)
library(sunburstR)

shinyServer(function(input, output, session) {
  
  # choices for filters
  stateChoices <- sort(unique(as.character(newData$State)))
  mobileChoices <- sort(unique(as.character(newData$DeviceIsMobile)))
  
  # reactive function to filter out data based on user input
  filterData <- reactive({
    input$go
    isolate({
      if(input$go < 1) {
        filteredData <- newData
      } else {
        filteredData <- newData[newData$State %in% input$state &
                                  newData$DeviceIsMobile %in% input$isMobile, ]
        validate(
          need(length(input$state) > 0,
               "Please select more than one state"),
          need(length(input$isMobile) > 0,
               "Please select more than one mobile options"),
          need(nrow(filteredData) > 0,
               paste0("Not sufficient Data available. 
                  Please select other filter options."))
        )
      }
    })
    
    if(input$browserDropDownInput != "All") {
      filteredData <- filteredData[filteredData$Browser == 
                                     input$browserDropDownInput, ]
    }
    if(input$resolutionDropDownInput != "All") {
      filteredData <- filteredData[filteredData$Resolution 
                                   == input$resolutionDropDownInput, ]
    }
    
    return(filteredData)
  })
  
  # get reactive state options
  output$stateCheckboxGroup <- renderUI({
    tags$div(class = "multicol",
             checkboxGroupInput("state", "States:",
                                choices  = stateChoices,
                                selected = stateChoices)
    )
  })
  
  # get reactive mobile options
  output$mobileCheckboxGroup <- renderUI({
    checkboxGroupInput("isMobile", "Mobile Options:",
                                choices  = mobileChoices,
                                selected = mobileChoices)
  })
  
  # observer function for states
  obsStates <- observe({
    if(input$stateSelectAll > 0) {
      if(input$stateSelectAll %% 2 == 0) {
        updateCheckboxGroupInput(session = session,
                                 inputId = "state",
                                 choices = stateChoices,
                                 selected = stateChoices)
        
      } else {
        updateCheckboxGroupInput(session = session,
                                 inputId = "state",
                                 choices = stateChoices,
                                 selected = c())
      }
    }
  })
  
  # observer function for mobile
  obsMobile <- observe({
    if(input$mobileSelectAll > 0) {
      if(input$mobileSelectAll %% 2 == 0) {
        updateCheckboxGroupInput(session = session,
                                 inputId = "isMobile",
                                 choices = mobileChoices,
                                 selected = mobileChoices)
        
      } else {
        updateCheckboxGroupInput(session = session,
                                 inputId = "isMobile",
                                 choices = mobileChoices,
                                 selected = c())
      }
    }
  })
  
  # drop down list for Browser choices
  output$browserDropDown <- renderUI({
    browserDropDownChoices <- append(sort(unique(newData$Browser)), "All")
    selectInput("browserDropDownInput", "Browser:",
                  choices = browserDropDownChoices,
                  selected = "All")
  })
  
  # drop down list for resolution choices
  output$resolutionDropDown <- renderUI({
    resolutionDropDownChoices <- append(unique(newData$Resolution), "All")
    selectInput("resolutionDropDownInput", "Resolution:",
                choices = resolutionDropDownChoices,
                selected = "All")
  })
  
  # output$predictionTable <- renderDataTable({
  #   final.test$UserAgentString <- NULL
  #   datatable(final.test,
  #             options = list(searching = FALSE,
  #                            paging = FALSE,
  #                            info = FALSE,
  #                            ordering = FALSE),
  #             rownames = FALSE) %>% formatPercentage(ncol(final.test), 2)
  # })
  
  output$bubbleChartDayOfWeek <- renderPlotly({
    # get filtered data
    newData <- filterData()
    
    # get only those columns which are required
    summaryData <- newData[, c("UserId", "Duration",
                               "TimeOfDay", "DayOfWeek", "PaymentComplete")]

    # set levels for days of the week
    summaryData$DayOfWeek <- factor(summaryData$DayOfWeek,
                                    levels = c("Sunday",
                                               "Monday",
                                               "Tuesday",
                                               "Wednesday",
                                               "Thursday",
                                               "Friday",
                                               "Saturday"))
  
    # make the opacity as 1 if policy is sold
    opacity <- ifelse(summaryData$PaymentComplete == "0", 0.1, 1)
    
    # remove payment complete column since it is no longer required
    summaryData$PaymentComplete <- NULL

    # plot the bubble chart
    p <- plot_ly(summaryData,
                 x = ~DayOfWeek,
                 y = ~TimeOfDay,
                 size = ~Duration,
                 type = "scatter",
                 mode = "markers",
                 sizes = c(as.numeric(min(summaryData$Duration)),
                           as.numeric(max(summaryData$Duration))),
                 marker = list(size = ~Duration/100,
                               opacity = opacity)) %>%
      layout(title = 'Day of Week vs Time of Day vs Duration (in minutes)',
             xaxis = list(showgrid = FALSE,
                          title = "Day Of Week"),
             yaxis = list(showgrid = FALSE,
                          range = c(0, 24),
                          title = "Time of Day")) 
  })
  
  output$bubbleChartDate <- renderPlotly({
    # get filtered data
    newData <- filterData()

    # get only those columns which are required
    summaryData <- newData[, c("UserId", "Date", "Duration",
                               "TimeOfDay", "PaymentComplete")]
    
    # make the opacity as 1 if policy is sold
    opacity <- ifelse(summaryData$PaymentComplete == "0", 0.1, 1)
    
    # remove payment complete column since it is no longer required
    summaryData$PaymentComplete <- NULL
    
    # plot the bubble chart
    p <- plot_ly(summaryData,
                 x = ~Date,
                 y = ~TimeOfDay,
                 size = ~Duration,
                 type = "scatter",
                 mode = "markers",
                 sizes = c(as.numeric(min(summaryData$Duration)),
                                    as.numeric(max(summaryData$Duration))),
                 marker = list(size = ~Duration/100,
                               opacity = opacity)) %>%
      layout(title = 'Date vs Time of Day vs Duration (in minutes)',
             xaxis = list(showgrid = FALSE,
                          range = c(as.numeric(as.POSIXct(
                            min(summaryData$Date), format="%Y-%m-%d"))*1000,
                                    as.numeric(as.POSIXct(
                                      max(summaryData$Date),
                                      format="%Y-%m-%d"))*1000),
                          type = "date",
                          title = "Date"),
             yaxis = list(showgrid = FALSE,
                          range = c(0, 24),
                          title = "Time of Day"))
  })
  
  output$sankeyDiagram <- renderGvis({
    # get filtered data
    newData <- filterData()
    
    # make a new data frame with values for number of sessions, when a user
    # passes from one event to another
    dat <- data.frame(From = c("Pre-Quote Portal",
                               "New to Quote Start",
                               "Quote Start",
                               "New to Retrieve Premium",
                               "Retrieve Premium",
                               "New to Bind Start",
                               "Bind Start",
                               "New to Payment Start",
                               "Payment Start",
                               "New to Payment Complete",
                               "Pre-Quote Portal",
                               "Quote Start",
                               "Retrieve Premium",
                               "Bind Start",
                               "Payment Start"),
                      To = c("Quote Start",
                             "Quote Start",
                             "Retrieve Premium",
                             "Retrieve Premium",
                             "Bind Start",
                             "Bind Start",
                             "Payment Start",
                             "Payment Start",
                             "Payment Complete",
                             "Payment Complete",
                             "Dropped After Pre-Quote Portal",
                             "Dropped After Quote Start",
                             "Dropped After Retrieve Premium",
                             "Dropped After Bind Start",
                             "Dropped After Payment Start"),
                      Sessions = c(nrow(newData[newData$PreQuotePortal == 1, ]),
                                 nrow(subset(newData, 
                                             newData$PreQuotePortal == 0 & 
                                               newData$QuoteStart == 1)),
                                 nrow(newData[newData$QuoteStart == 1, ]),
                                 nrow(subset(newData,
                                             newData$QuoteStart == 0 &
                                               newData$RetrievePremium == 1)),
                                 nrow(newData[newData$RetrievePremium == 1, ]),
                                 nrow(subset(newData,
                                             newData$RetrievePremium == 0 &
                                               newData$BindStart == 1)),
                                 nrow(newData[newData$BindStart == 1, ]),
                                 nrow(subset(newData,
                                             newData$BindStart == 0 &
                                               newData$PaymentStart == 1)),
                                 nrow(newData[newData$PaymentStart == 1, ]),
                                 nrow(subset(newData,
                                             newData$PaymentStart == 0 &
                                               newData$PaymentComplete == 1)),
                                 nrow(newData[newData$PreQuotePortal == 0, ]),
                                 nrow(newData[newData$QuoteStart == 0, ]),
                                 nrow(newData[newData$RetrievePremium == 0, ]),
                                 nrow(newData[newData$BindStart == 0, ]),
                                 nrow(newData[newData$PaymentStart == 0, ])
                                ))
    
    # plot the sankey diagram
    sankeyPlot <- gvisSankey(dat, from="From", to="To", weight="Sessions",
                      options = list(width = "automatic", height = "400"))
  
    return(sankeyPlot)
  })
  
  output$sunburstPlot <- renderSunburst({
    # # make a copy for sunburst diagram
    # sequences <- data[, c("Event", "UserId", "InteractionId", "State")]
    # 
    # # keep only those events which are interesting
    # keep <- c("Pre-Quote Portal", "Retrieve Existing Policy",
    #           "Quote Start", "Retrieve Premium", "Bind Start",
    #           "Add Drivers", "Add Vehicles", "Payment Start",
    #           "Payment Complete", "Download Receipt", "Referred to Phone Rep",
    #           "Choose Coverage", "Get Premium")
    # 
    # sequences <- sequences[sequences$Event %in% keep, ]
    # 
    # # make one row per user and interaction
    # sequences <- setDT(sequences)[, lapply(.SD, 
    #                                        function(x) toString(na.omit(x))),
    #                               by = list(UserId, State, InteractionId)]
    # 
    # sequences$Event <- gsub("Pre-Quote Portal", "PreQuotePortal", 
    #                         sequences$Event)
    # sequences$Event <- gsub("Retrieve Existing Policy", 
    #                         "RetrieveExistingPolicy",
    #                         sequences$Event)
    # sequences$Event <- gsub("Quote Start", "QuoteStart", sequences$Event)
    # sequences$Event <- gsub("Retrieve Premium", "RetrievePremium",
    #                         sequences$Event)
    # sequences$Event <- gsub("Bind Start", "BindStart", sequences$Event)
    # sequences$Event <- gsub("Add Drivers", "AddDrivers", sequences$Event)
    # sequences$Event <- gsub("Add Vehicles", "AddVehicles", sequences$Event)
    # sequences$Event <- gsub("Payment Start", "PaymentStart", sequences$Event)
    # sequences$Event <- gsub("Payment Complete", "PaymentComplete", 
    #                         sequences$Event)
    # sequences$Event <- gsub("Download Receipt", "DownloadReceipt", 
    #                         sequences$Event)
    # sequences$Event <- gsub("Referred to Phone Rep", "ReferredToPhoneRep",
    #                         sequences$Event)
    # sequences$Event <- gsub("Choose Coverage", "ChooseCoverage", 
    #                         sequences$Event)
    # sequences$Event <- gsub("Get Premium", "GetPremium", sequences$Event)
    # sequences$Event <- gsub(', ', '-', sequences$Event)
    # 
    # # remove columns which are no longer necessary
    # sequences$UserId <- NULL
    # sequences$State <- NULL
    # sequences$InteractionId <- NULL
    # 
    # # aggregate for sunburst diagram
    # sequences <- aggregate(sequences$Event,
    #                        by = list(Event = sequences$Event),
    #                        FUN = "length")
    # return(sunburst(sequences))
  })
  
  # suspend the observer functions when session is ended
  session$onSessionEnded(function() {
    obsStates$suspend()
    obsMobile$suspend()
  })
})
