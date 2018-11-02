#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#



if (file.exists("~/.checkpoint/2018-08-01")){
  library(checkpoint)
  checkpoint("2018-08-01", scanForPackages = FALSE)  
}

library(MASS)
library(shiny)
library(plotly)
library(jsonlite)
library(listviewer)


pointcloud <- function(N, nvars, variance, xycovar){
  mu  = rep(0, nvars)
  
  Sigma       = matrix(1, nvars, nvars)
  diag(Sigma) = variance          
  covar       = rep(0, nvars*(nvars-1)/2)
  covar[1]    = xycovar
  Sigma[upper.tri(Sigma)] = covar                 
  Sigma[lower.tri(Sigma)] = t(Sigma)[lower.tri(Sigma)]
  
  mvrnorm(n = N, mu, Sigma)
}


generate = function(N, seed, variance=1, xycovar=.7, mean_direction=45, sd_direction=20){
  
  # Parameters ------------------------------------
  
  SEED         = seed
  SKEWED       = FALSE
  SKEW_BASE    = 10
  color_palette = viridis::viridis_pal(direction=-1)(50)
  
  
  # Sample positions from a multivariate normal ------------------
  set.seed(SEED)
  
  points = pointcloud(N, 2, variance, xycovar)
  
  # Scale to [0, 1] range ---------------------------------------
  
  Frame1 = data.frame(
    x     = approx(range(points[,1]), c(0,1), xout=points[,1])$y,
    y     = approx(range(points[,2]), c(0,1), xout=points[,2])$y
  )
  
  # Sample size from a normal ------------------------------------
  
  size = rnorm(N)
  Frame1$size = approx(range(size), c(0,1), xout=size)$y
  
  # Sample color from a normal -----------------------------------
  
  color = rnorm(N)
  Frame1$color = approx(range(color), c(0,1), xout=color)$y
  # Frame1$color = color_palette[cut(color, 50)]
  
  # Sample direction (theta) from a normal ----------------------
  
  Frame1$theta = rnorm(N)
  
  change = rnorm(N)
  Frame1$change = approx(range(change), c(0.05,.2), xout=change)$y
  
  # Sample Direction --------------------------
  
  # mean_theta  = if (xycovar < 0) 5.49779 else .25*pi # if it's uptrend then 45 deg
  mean_theta = (mean_direction/180)*pi
  sd_theta   = (sd_direction/180)*pi

  
  # Frame1$theta = rep(mean_theta, N)
  Frame1$theta = rnorm(N,mean_theta, sd_theta)
  
  # Create second frame ---------------------------
  
  Frame2 = data.frame(x = Frame1$x + Frame1$change*cos(Frame1$theta),
    y      = Frame1$y + Frame1$change*sin(Frame1$theta),
    size   = Frame1$size,
    color  = Frame1$color,
    change = Frame1$change,
    theta  = Frame1$theta,
    stringsAsFactors = F)
  
  
  return(list(
    Frame1 = Frame1,
    Frame2 = Frame2
  ))
}




# Define UI for application that draws a histogram
ui <- fluidPage(
   
   # Application title
   titlePanel("Trendmaker"),
   
   # Sidebar with a slider input for number of bins 
   sidebarLayout(
      sidebarPanel(
         numericInput("seed", "Seed", 1),
         sliderInput("covar",
                     "Covariance (xy):",
                     min = -1,
                     max = 1,
                     step = .1,
                     value = 0.7),
        numericInput("N", "Dataset size (N)", 50),
        numericInput("variance", "Variance", 1, min=.1, step = .1),
        sliderInput("mean_direction", "Mean Direction", value=45, min=0, max=360),
        sliderInput("sd_direction", "Std. Dev. Direction", value=10, min=0, max=180)
      ),
      
      # Show a plot of the generated distribution
      mainPanel(
        tabsetPanel(
          tabPanel("Plot", plotlyOutput("plot", height="600px", width="600px")),
          tabPanel("Data", reactjsonOutput("json", height="600px")) 
        )
         
      )
   )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
   
  update = reactive({
    
    covar <- input$covar
    variance <- input$variance
    N <- input$N
    seed <- input$seed
    mean_direction <- input$mean_direction
    sd_direction <- input$sd_direction
    
    sim = generate(N, seed, variance, covar, mean_direction, sd_direction)
    sim$Frame1[, "frame"] = 1
    sim$Frame2[, "frame"] = 2
    df = rbind(sim$Frame1, sim$Frame2)
    
    list(
      dataset = df
    )
    
  })
  
   output$plot <- renderPlotly({
      updated_objects <- update()
      
      dataset = updated_objects$dataset
      
      dataset %>%
      plot_ly(
        x = ~x,
        y = ~y,
        size = ~size,
        color = ~color,
        frame = ~frame,
        type = 'scatter',
        mode = 'markers',
        showscale = F
      ) %>%
      hide_colorbar() %>%
      animation_opts(redraw = T)
   })
   
   output$json <- renderReactjson({
     updated_objects <- update()
     
     dataset = updated_objects$dataset
     
     reactjson(toJSON(dataset))
   })
}

# Run the application 
shinyApp(ui = ui, server = server)

