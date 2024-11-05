table_macro <- function(data,
                        shock = "ct1",
                        relative_variation = NULL,
                        level_diff = NULL,
                        percent_diff = NULL,
                        order = NULL,
                        time_vector = if(exists("time_waypoints")){time_waypoints}else{c(1,2,3,5,10,30,60)},
                        end_year = 2050,
                        shock_year = 2021,
                        digits_numb = 2
){
  
  if(is.null(order)){
    order <- c(relative_variation, level_diff,percent_diff)
  }
  #Filter data
  data <- data |> 
    filter(scenario == shock) |> 
    select(-scenario)
  
  #Years selected for the macroeconomic result tables
  max_year_possible <- end_year - shock_year
  time_horizon_1 <- c(time_vector, end_year - shock_year) |> unique()
  time_horizon <- time_horizon_1[time_horizon_1 <= max_year_possible ] 
  
  years_ret <- c(shock_year,c(rep(shock_year, length(time_horizon))) + time_horizon)
  label_period = c("t",paste("t +",time_horizon[time_horizon <  (end_year - shock_year)]),"Long term")
  #label_period[label_period == "t + 0"] <- "t"
  replacement_vector_time <- label_period |> set_names(years_ret)
  
  #Footnotes
  footnote = paste(paste0("% : ",("relative variation")),paste0("\U0394 : ",("absolute variation (compared to baseline)")),paste0("pp : ",("percentage point variation")),sep = ", ")
  
  #Create the result dataframe for shocks before transforming it into a flextable
  data_relative_variation <- data |> 
    filter(variable %in% relative_variation) |> 
    mutate(values = round((values/values_ref-1)*100,
                          digits = digits_numb),
           unit = "%")
  
  data_level_diff <- data |> 
    filter(variable %in% level_diff) |> 
    mutate(values = round((values - values_ref),
                          digits = digits_numb),
           unit = "\U0394")
  
  data_percent_diff <- data |> 
    filter(variable %in% percent_diff) |> 
    mutate(values = round((values - values_ref)*100, 
                          digits = digits_numb),
           unit = "pp")
  
  table_macro <- rbind(data_relative_variation,data_level_diff,data_percent_diff) |> 
    filter(year %in% years_ret,
           variable %in% order) |> 
    mutate(year = str_replace_all(year,replacement_vector_time)) |> 
    select(Variable = variable,year,values," " = unit) |> 
    pivot_wider(names_from = year, values_from = values) |>
    arrange(factor(Variable, levels = order)) |> 
    # left_join(group,by = "Variable") |> 
    mutate(Variable = Variable) # |>
    # as_grouped_data(groups = c("group"), columns = NULL,expand_single = FALSE) |> select(-group)
  
  return(table_macro)
}
