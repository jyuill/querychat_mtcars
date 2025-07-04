# Querychat for Shiny!
# copied directly from
# https://github.com/posit-dev/querychat
# detailed documentation: https://github.com/posit-dev/querychat/blob/main/pkg-r/README.md
# querychat is a drop-in component for Shiny that allows users
#  to query a data frame using natural language. 
# The results are available as a reactive data frame, 
# so they can be easily used from Shiny outputs, 
# reactive expressions, downloads, etc.

library(shiny)
library(bslib)
library(querychat) # install if needed: pak::pak("posit-dev/querychat/pkg-r")
# - seems to incorporate some elements from ellmer - can be useful to include it anyway
library(ellmer)
library(tidyverse)
library(DT)
library(plotly)

barcolor <- "#0072B2"

# get the data by modifying mtcars
# move car names from row namse to their own column and place it first
mtcars_mod <- mtcars %>% 
  mutate(
    car = rownames(mtcars)
  ) %>% 
  select(car, everything())
# switch out car names as row names for numbers
rownames(mtcars_mod) <- seq(1:nrow(mtcars_mod))
# convert car names to factor for sorting etc
mtcars_mod$car <- as.factor(mtcars_mod$car)

# 1. CONFIGURE querychat. This is where you specify the dataset and can also
#    add/edit options like:
#    - greeting message
#    - system prompt ('extra instructions')
#    - model (uses system from ellmer -> incl below)
#      - usu. need API key in .Renviron
#      - setting max_tokens to limit response length 
#         - need to have leeway for long enough answers but don't want to 
#           inadvertently run up costs (even though cheap model)
#    - API key if needed
#    - data description
querychat_config <- querychat_init(mtcars_mod,
  greeting = readLines("greeting.md"),
  data_description = readLines("data_description.md"),
  create_chat_func = purrr::partial(ellmer::chat_anthropic, 
    model = "claude-3-5-haiku-20241022", params=(list(max_tokens=500))))

ui <- page_sidebar(
  titlePanel("Gen AI: using querychat for natural language queries of a dataset"),
  h4("Use panel at left to sort, filter, ask questions about the data."),
  # 2. Use querychat_sidebar(id) in a bslib::page_sidebar.
  #    Alternatively, use querychat_ui(id) elsewhere if you don't want your
  #    chat interface to live in a sidebar.
  sidebar = querychat_sidebar("chat"),
  # show three plots beside each other in one row 
  fluidRow(
    column(5, plotOutput("plot_mpg", height="650px")),
    column(3, plotOutput("plot_mpg_hist", height="650px")),
    column(4, plotlyOutput("plot_mpg_qsec", height="650px"))
  ),
  DT::DTOutput("dt")
)

server <- function(input, output, session) {

  # 3. Create a querychat object using the config from step 1.
  querychat <- querychat_server("chat", querychat_config)

  output$plot_mpg <- renderPlot({
    # 4. Use the filtered/sorted data frame anywhere you wish, via the
    #    querychat$df() reactive.
    ggplot(querychat$df(), aes(x = reorder(car, mpg), y = mpg)) +
      geom_col(fill=barcolor)+coord_flip()+theme_minimal()+
      theme(axis.text.y = element_text(size=12)) +
      labs(x="", y="MPG")
  })

  output$plot_mpg_hist <- renderPlot({
    # 4. Use the filtered/sorted data frame anywhere you wish, via the
    #    querychat$df() reactive.
    ggplot(querychat$df(), aes(x = mpg)) +
      geom_histogram(fill=barcolor)+theme_minimal()+
      labs(y="", x="MPG distribution")
  })

  output$plot_mpg_qsec <- renderPlotly({
    # 4. Use the filtered/sorted data frame anywhere you wish, via the
    #    querychat$df() reactive.
    p <- ggplot(querychat$df(), aes(x=mpg, y = qsec, color=car)) +
      geom_point(size=2)+theme_minimal()+
      theme(legend.text = element_text(size=10)) +
      labs(x="MPG", y="1/4 mile time (secs)")
    ggplotly(p)
  })

  output$dt <- DT::renderDT({
    # 4. Use the filtered/sorted data frame anywhere you wish, via the
    #    querychat$df() reactive.
    DT::datatable(querychat$df() %>% arrange(car), 
      options = list(
      lengthMenu = list(c(20, 50, 100, -1), c('20', '50', '100', 'All')),
      displayLength = 20
  ))
  }
  )
}

shinyApp(ui, server)