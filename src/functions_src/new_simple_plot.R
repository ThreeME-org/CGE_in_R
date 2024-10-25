## New simple_plot 

simple_plot <- function (data, variables , label_series = NULL, 
                      startyear = NULL, 
                       endyear = NULL, 
                      transformation = "reldiff", 
                      unit = "percent", 
                       decimal = 0.1, 
                       titleplot = NULL, 
                       scenario = NULL, 
                      percent_label = TRUE, 
                      custom_x_breaks = NULL,  
                       name_baseline = "baseline") 
{ 
  
  series = variables
   
  if(sum(variables %in% data$variable) == 0 ){stop("Cannot find the specified variables")}
  format_img <- c("svg")
  pal <- custom.palette(n = length(series)) |> purrr::set_names(series)
  
  transfo <- c("reldiff","gr","diff","level") |> purrr::set_names()
  var_transform = transfo[transformation]
  
  if(is.null(scenario)){
    scenario <- unique(data$scenario) 
  }
  
  if (is.null(label_series)) { label_series = series  }
  
  data_plot  <- data |> filter(variable %in% variables, scenario %in%scenario) 
  
  if(var_transform == "reldiff"){
    data_plot  <- data |> filter(variable %in% variables, scenario %in%scenario)  |> 
      mutate(to_plot = values/values_ref - 1 ) |> 
      filter(index_scen == 0 )
  }
  if(var_transform == "gr"){
    data_plot  <- data |> filter(variable %in% variables, scenario %in%scenario)  |> 
      group_by(variable, scenario) |>  arrange(year) |> 
      mutate(to_plot = values/lag(values) - 1 ) |> 
      ungroup()
  }
  
  if(var_transform == "diff"){
    data_plot  <- data |> filter(variable %in% variables, scenario %in%scenario)  |> 
      mutate(to_plot = values - values_ref ) |> 
      filter(index_scen == 0 )
  }
  if(var_transform == "level"){
    data_plot  <- data |> filter(variable %in% variables, scenario %in%scenario)  |> 
      mutate(to_plot = values  )
  }
  
  if(is.null(endyear)){endyear= max(data$year, na.rm = TRUE)}
  if(is.null(startyear)){startyear= min(data$year, na.rm = TRUE)}
  
  plot <- data_plot |> ggplot(aes ( x = year, y = to_plot)) +
    
    geom_line(aes(colour= variable, linetype = scenario))  


  if (percent_label == TRUE) {
    lab_percent <- "%"
  }  else {
    lab_percent <- ""
  }
  if (is.null(custom_x_breaks)) {
    n_years <- endyear - startyear
    algo_x_breaks <- 10
    if (n_years <= 35) {
      algo_x_breaks <- 5
    }
    if (n_years <= 20) {
      algo_x_breaks <- 2
    }
    if (n_years <= 10) {
      algo_x_breaks <- 1
    }
    break_x_sequence <- seq(from = startyear, to = endyear, 
                            by = algo_x_breaks)
  } else {
    if (is.numeric(custom_x_breaks)) {
      break_x_sequence <- seq(from = startyear, to = endyear, 
                              by = custom_x_breaks)
    }  else { break_x_sequence <- waiver()}
  }
  
  plotseries <- plot + scale_x_continuous(breaks = break_x_sequence) + 
    scale_y_continuous(labels = scales::percent_format(accuracy = decimal, 
                                                       suffix = lab_percent)) + 
    scale_color_manual(values = pal, 
                       limits = series, labels = label_series) + 
    labs(x = NULL,  y = NULL, title = titleplot) + 
    
    ofce::theme_ofce(base_family = "")+ 
    theme(
          axis.title.y = element_blank(), 
          axis.ticks = element_line(linewidth  = 0.5,   colour = "grey42"), 
          legend.position = "bottom")
  
  if (unit != "percent") {
    plotseries <- plotseries + scale_y_continuous(labels = scales::label_number(accuracy = decimal, 
                                                                                scale = unit))
  }
 
  plotseries
  
}
