table_reference <- function(data = output_model_1,
                            ref_name = "baseline",
                            growth_var = NULL,
                            percentage_var = NULL,
                            index_shockyear = NULL,
                            order = NULL,
                            time_vector = c(0,1,5,10,20),
                            end_year = 2050,
                            shock_year = 2021,
                            digits_numb = 2,
                            language = "en",
                            trad_base = NULL
){
  


  
  
  if(!is.null(trad_base)){
    trad <- purrr::partial(ermeeth::trad, data = label_tables)
  }
  
  if(is.null(order)){
    order <- c(growth_var, percentage_var)
  }
  
  
  #Filter data
  data <- data |> 
    filter(scenario == ref_name) |> 
    select(-scenario)
  
  #Years selected for the macroeconomic result tables
  max_year_possible <- end_year - shock_year
  time_horizon_1 <- c(time_vector, end_year - shock_year) |> unique()
  time_horizon <- time_horizon_1[time_horizon_1 <= max_year_possible ] 
  
  years_ret <- c(rep(shock_year, length(time_horizon))) + time_horizon
  label_period = c(paste("t +",time_horizon[time_horizon <  (end_year - shock_year)]),"Long term")
  label_period[label_period == "t + 0"] <- "t"
  replacement_vector_time <- label_period |> set_names(years_ret)
  
  #Footnote 
  footnote_reference = paste(paste0("% : ","in percentage"),paste0("\U2197 : ","annual growth rate"," (","in %",")"),paste0("t₀=1 : ","index (start year = 1)"),sep = ", ")
  
  #Create the result dataframe for the reference scenario before transforming it into a flextable
  data_reference_a <- data |> 
    filter(variable %in% growth_var) |> 
    group_by(variable) |> arrange(year) |> 
    mutate(
           values = round((values/lag(values) - 1)*100,
                          digits = digits_numb),
           variable = variable,
           unit = "\U2197") |> 
    ungroup()
  
  data_reference_b <- data |> 
    filter(variable %in% percentage_var) |> 
    mutate(values = round(values*100,
                          digits=digits_numb),
           variable = variable,
           unit = "%")
  
  data_reference_c <- data |> 
    filter(variable %in% index_shockyear) |> 
    group_by(variable) |>
    mutate(values = round(values/values[which(year == shock_year)],digits = digits_numb)) |> 
    ungroup() |>
    mutate(variable =variable,
           unit = "t₀=1")|> 
    filter(year %in% years_ret) |> 
    mutate(year = str_replace_all(year,replacement_vector_time)) |> 
    select(Variable = variable,year,values," " = unit) |> 
    pivot_wider(names_from = year, values_from = values)
  
  
  data_reference <- rbind(data_reference_a,data_reference_b) |> 
    filter(year %in% years_ret) |> 
    mutate(year = str_replace_all(year,replacement_vector_time)) |> 
    select(Variable = variable,year,values," " = unit) |> 
    pivot_wider(names_from = year, values_from = values) |> 
    arrange(factor(Variable, levels = order)) |> 
    rbind(data_reference_c)
  
  
  res <- data_reference
  
  return(res)
}

