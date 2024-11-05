##load excel calib


load_excel_calibration<- function(excel_sheet = "configuration/scenarii_calib/scenarii_inputs.xlsx", 
                                  sheet_to_load = "baseline",
                                  calib_base = "src/compiler/calib.csv",
                                  base_year = baseyear,
                                  check_tol = 10e-8,
                                  stop_if_calib_fail = TRUE,
                                  keep_baseyear_calib_data = TRUE
){
  
  wyellow <- function(text){crayon::yellow(crayon::bgBlack(text) )}

  
  xl_data <- read_excel(excel_sheet,sheet = sheet_to_load )
  
  ###Importing and cleaning excel data
  names(xl_data)[c(1:2)]<- c("to_load","variable")
  import_base <- xl_data %>% filter(to_load != 0) %>% select(-to_load) %>% 
    t() %>% as.data.frame()
  
  years <- row.names(import_base)[-1] %>% as.numeric()
  vars <- import_base[1,] %>% as.vector() %>% reduce(c) %>% tolower()
  
  cleaned_base <- import_base[-1,]  %>% as.data.frame() %>%  
    rename_all(~vars)%>% 
    mutate(year = years) %>% 
    mutate_all(~str_remove_all(.x,"\\s")  %>% as.numeric())
  
  calib_data <- fread(calib_base, data.table = FALSE) %>% 
    select(-baseyear) %>% 
    mutate(year = year + baseyear) 
  
  
  original_data <- calib_data %>% select(year, any_of(vars))
  vars_not_prexisting <- setdiff(names(cleaned_base),names(original_data))
  
  if(length(vars_not_prexisting)>0){
    cat(paste0("\nThe following variables were found in the excel sheet but not in calib files:\n"))
    cat(vars_not_prexisting, sep = "\n")
    cat("\nThey will be added anyways\n")}
  
  
  ##baseyear check 
  check <- original_data[which(original_data$year==base_year),] - (cleaned_base %>% select(all_of(names(original_data))) )[which(cleaned_base$year==base_year),]
  
  test <- check[which(abs(check)>check_tol)] %>% names()
  if(length(test)>0){
    
    cat(wyellow("\nThe following variables do not match calibrated data at base year:\n") ) 
    cat(test, sep = "\n")
    cat("\n")
    if(stop_if_calib_fail){stop("Mismatch with calibrated data")}else{
      if(keep_baseyear_calib_data){
        cat(wyellow("Continuing replacing with the calibrated data for the baseyear"))
      }else{
        cat(wyellow("Continuing with new data loaded from Excel"))}
    }
    
  }
  if(keep_baseyear_calib_data){ base_i = 0}else{base_i = 1}
  
  ###finding which vars to fill
  data_na <- original_data %>% mutate_at(setdiff(names(.),"year"), ~ifelse(year<=(base_year-base_i),.x,NA)) 
  imported_base <- cleaned_base  %>% mutate_at(setdiff(names(.),"year"), ~ifelse(year==(base_year*(1-base_i)),NA,.x)) 
  
  joined<- full_join(data_na,imported_base, by="year") 
  vars_to_merge <- names(joined)[which(grepl(".+\\.x$",names(joined)))] %>% str_remove("\\.x$") 
  
  merged <- map(vars_to_merge,
                function(vari=.x){
                  joined %>% select(all_of(c("year",str_c(vari, c(".x",".y")) ))) %>%
                    mutate_at(str_c(vari,".x") , ~ifelse(is.na(.x),joined[,str_c(vari,".y")] ,.x)  )
                }) %>% reduce(left_join,by = "year") %>% 
    select(all_of(c("year",str_c(vars_to_merge,".x")))) 
  names(merged) <-   names(merged) %>% str_remove("\\.x$")
  
  ready_data <-full_join(merged,joined, by = "year") %>% select(-ends_with(".y"))%>% select(-ends_with(".x"))

  ### FILLING IN THE BLANKS
  vars_to_fill <- names(ready_data)[which( (ready_data %>% map(~sum(is.na(.x))) %>% reduce(c))>0)]
  
  if(length(vars_to_fill >0))
    
  {filler <- vars_to_fill %>% map(
    function(vari=.x){
      years_b = ready_data$year
      plop <- ready_data %>% select(all_of(c("year",vari))) %>% 
        filter_all(~!is.na(.x)) 
      ermeeth::interpolation_series ( date_vector = plop[,"year"],
                                      value_vector = plop[,vari],
                                      first.date = min(years_b),
                                      last.date = max(years_b)) 
    }
    
  ) %>% purrr::set_names(vars_to_fill) %>%  purrr::reduce(cbind) %>% as.data.frame()%>% purrr::set_names(vars_to_fill) %>% 
    mutate(year = ready_data$year)
  
  ### completed data
  complete_data <- ready_data %>% select(-all_of(vars_to_fill)) %>% full_join(filler, by="year")
  }else{
    complete_data <- ready_data
  }
  
  res<- complete_data
  
}
