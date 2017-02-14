library(shiny)
library(DT)
library(plotly)
library(sunburstR)

shinyUI(fluidPage(   
  tags$head(
    tags$style(
      HTML(
        ".multicol .shiny-options-group {
             -webkit-column-count: 3; /* Chrome, Safari, Opera */
             -moz-column-count: 3; /* Firefox */
             column-count: 2;
             }")
      )
    ),
  titlePanel("CIA Data"),
  
  sidebarLayout(
    sidebarPanel(
     
      uiOutput("mobileCheckboxGroup"),
      actionButton("mobileSelectAll",
                   label = "Select/Deselect All Mobile Options"),
      br(),
      br(),
      
      uiOutput("browserCheckboxGroup"),
      actionButton("browserSelectAll",
                   label = "Select/Deselect All Browsers"),
      br(),
      br(),
      
      uiOutput("resolutionCheckboxGroup"),
      actionButton("resolutionSelectAll",
                   label = "Select/Deselect All Resolution"),
      br(),
      br(),
      
      uiOutput("stateCheckboxGroup"),
      actionButton("stateSelectAll",
                   label = "Select/Deselect All States"),
      br(),
      br(),
      actionButton("go", "Apply Selected Filters"),
      width = 3
    ),
    mainPanel(   
    tabsetPanel(id = "tabs",
      tabPanel("User Pathways",
               br(),
               htmlOutput("sankeyDiagram"),
               br(),
              
               sunburstOutput("sunburstPlot", 
                              height = "400px",
                              width = "100%"),
               tags$head(tags$script(HTML("
                         $(document).ready(function(e) {
                            $('.sunburst-sidebar').remove();
                         })
                         ")))
              ),
      tabPanel("Time Dependency",
               br(),
               plotlyOutput("bubbleChartDate"),
               br(),
               plotlyOutput("bubbleChartDayOfWeek")
      ),
      tabPanel("Predictive Analysis",
               br(),
               dataTableOutput("predictionTable")
               )
            )
        )
    )
))
