translate_modelprg <- function(
    modfile = file.path("src", "compiler", "model.prg"),
    calibfile = file.path("src", "compiler", "calib.csv"),
    base.year = baseyear,
    last.year = lastyear ){
# browser()
 error <- c(NA)     
# 1. loading files the model 

model_equations <- read_lines(modfile) 

data_3me <- data.table::fread(calibfile,data.table = FALSE)  %>% select(-all_of("baseyear")) 
data_3me$year = data_3me$year + base.year

data_3me <- data_3me %>% filter(year <= last.year)

# 2. Transformation to tresthor syntax
model_file <-model_equations %>%
  tolower() %>%
  str_replace_all("^a_3me\\.append",replacement ="") %>%
  str_replace_all("\\s+",replacement ="") %>%
  str_replace_all("@year","year")

model_file <- model_file[grepl("^$",model_file)==FALSE]

# 3. Checking and treating elem
elem <- model_file %>% 
  str_extract_all("@elem\\([^,]+,\\d+\\)") %>% 
  compact() %>% unlist() %>% unique()

if(!is.null(elem)){
elem_case_1 <- elem[grep(pattern = "@elem\\(\\w+,\\d+\\)", elem)]
elem_case_2 <- elem[grep(pattern = "@elem\\(\\w+\\(-\\d+\\),\\d+\\)", elem)]


## 3.1. Simple elem with just the year
if(length(elem_case_1)>0){
elem_table_1 <- data.frame(original = elem_case_1) %>% 
  mutate(year = as.numeric(str_replace(original,"@elem\\(\\w+,(\\d+)\\)","\\1")) ,
         var_A  = str_replace(original,"@elem\\((\\w+),\\d+\\)","\\1"),
         var_B = NA,
         operation = NA,
         new_var_name = paste("elem",var_A,year, sep = "_"))
}

## 3.2. elem with a lag and the year
if(length(elem_case_2)>0){
elem_table_2 <- data.frame(original = elem_case_2) %>% 
  mutate(year = 
           as.numeric(str_replace(original,"@elem\\(\\w+\\(-\\d+\\),(\\d+)\\)","\\1") ) -
           as.numeric(str_replace(original,"@elem\\(\\w+\\(-(\\d+)\\),\\d+\\)","\\1")),
         var_A  = str_replace(original,"@elem\\((\\w+)\\(-\\d+\\),\\d+\\)","\\1"),
         var_B = NA,
         operation = NA,
         new_var_name = paste("elem",var_A,year, sep = "_"))
}

elem_table <- rbind(elem_table_1,elem_table_2)

elem_value <- purrr::set_names(elem_table$year,elem_table$var_A) %>% 
  imap_dfr(~c(.y , data_3me[which(data_3me$year == .x),.y] )  ) %>% t() %>% as.data.frame() %>% 
  rename(var_A = V1, value = V2) %>% mutate(value = as.numeric(value))

elem_table <- elem_table %>% left_join(elem_value, by = "var_A")
rownames(elem_table) <- elem_table$new_var_name


## 3.3. More complex elems with operations on the variables
elem_case_3 <- elem[grep(pattern = "@elem\\(\\w+[\\+\\-\\*\\/]\\w+,\\d+\\)", elem)]

if(length(elem_case_3)>0){
elem_table_3 <- data.frame(original = elem_case_3) %>% 
  mutate(year = as.numeric(str_replace(original,"@elem\\(\\w+[\\+\\-\\*\\/]\\w+,(\\d+)\\)","\\1")) ,
         var_A  = str_replace(original,"@elem\\((\\w+)[\\+\\-\\*\\/]\\w+,\\d+\\)","\\1"),
         var_B  = str_replace(original,"@elem\\(\\w+[\\+\\-\\*\\/](\\w+),\\d+\\)","\\1"),
         operation = str_replace(original,"@elem\\(\\w+([\\+\\-\\*\\/])\\w+,\\d+\\)","\\1"),
         new_var_name = paste("elem",var_A,var_B, year, sep = "_"))
rownames(elem_table_3) <- elem_table_3$new_var_name


## 3.3.1 Function to replace elems with calculated values  

get_and_compute_variable <- function(elemtable,varname,year){

  op_to_use = elemtable[varname,"operation"]
  if (op_to_use == "+"){
    value <- data_3me[which(data_3me$year == year), elemtable[varname,"var_A"] ] + data_3me[which(data_3me$year == year),elemtable[varname,"var_B"]]
  }
  if (op_to_use == "-"){
    value <- data_3me[which(data_3me$year == year), elemtable[varname,"var_A"] ] - data_3me[which(data_3me$year == year),elemtable[varname,"var_B"]]
  }
  if (op_to_use == "*"){
    value <- data_3me[which(data_3me$year == year), elemtable[varname,"var_A"] ] * data_3me[which(data_3me$year == year),elemtable[varname,"var_B"]]
  }
  if (op_to_use == "/"){
    value <- data_3me[which(data_3me$year == year), elemtable[varname,"var_A"] ] / data_3me[which(data_3me$year == year),elemtable[varname,"var_B"]]
  }
  c(varname,value)
}

elem_value_3 <- purrr::set_names(elem_table_3$year,elem_table_3$new_var_name) %>% 
  imap_dfr(~get_and_compute_variable(elem_table_3,.y,.x) ) %>% 
  t() %>% as.data.frame() %>% 
  rename(new_var_name = V1, value = V2) %>% mutate(value = as.numeric(value))

elem_table_3 <- elem_table_3 %>% left_join(elem_value_3, by = "new_var_name")
elem_table <- rbind(elem_table, elem_table_3) 

rm(elem_table_3,elem_value_3)}



elem_table$original_regex <- elem_table$original %>%
  str_replace_all("\\(","\\\\(") %>% 
  str_replace_all("\\)","\\\\)") %>% 
  str_replace_all("\\+","\\\\+") %>% 
  str_replace_all("\\-","\\\\-") %>% 
  str_replace_all("\\/","\\\\/") %>% 
  str_replace_all("\\*","\\\\*") 

rownames(elem_table) <- elem_table$new_var_name

## 3.4 Add the elems in the database
data_3me <- tresthor::add_coeffs(elem_table, database = data_3me,
pos.coeff.name = "new_var_name", 
pos.coeff.value = "value")

model_file <-str_replace_all(model_file, 
                             set_names(elem_table$new_var_name,elem_table$original_regex))}


##lag/ delta transformation

model_file <-model_file %>%
  str_replace_all("(\\w+)\\((-\\d+)\\)","lag(\\1,\\2)") %>% 
  str_replace_all("(?<!\\w)d\\(","delta(1,") %>% 
  str_replace_all("\\+-","-")

# 4 Conditionalities

model_file <-model_file %>%
  str_replace_all("log\\(pe_s\\w+\\)-log\\(p\\)>0","1") %>% 
  str_replace_all("pnos\\*nos<=1e-05","0") %>% 
  str_replace_all("1e(-\\d+)","(10^(\\1))")  %>% 
  # str_replace_all("(\\w+)\\^(\\(1-\\w+\\))","exp(\\2*log(\\1))") %>%  ## THREEME specific
  # str_replace_all("=(\\(.+\\))\\^(\\(.+\\)$)","=exp(\\2*log(\\1))") %>%  ## THREEME specific
  str_replace_all("\\((verif_pch_c[a-z]{2})\\^2\\)\\^\\(1/2\\)","abs(\\1)") %>%  ## THREEME specific
  str_replace_all("delta\\(1,log\\((\\w+)/(\\w+)\\)-log\\((\\w+)/(\\w+)\\)\\)","((log(\\1)-log(\\2)-log(\\3)+log(\\4))-(log(lag(\\1,-1))-log(lag(\\2,-1))-log(lag(\\3,-1))+log(lag(\\4,-1))))") 
  # str_replace_all("(\\(\\w+/lag\\(\\w+,-1\\)\\))\\^(\\(1/\\w+\\))","(exp(\\2*log(\\1)))") 



# 5 Complicated powers
#model_file <-model_file %>%
#str_replace_all("(\\w+)\\^(\\([a-z0-9_\\+\\-\\/\\*\\.]+\\))","exp(\\2*log(\\1))") %>%
#str_replace_all("(\\([a-z0-9_\\+\\-\\/\\*\\.]+\\))\\^(\\([a-z0-9_\\+\\-\\/\\*\\.]+\\))","exp(\\2*log(\\1))") 

###If there are conditions left , rewrite them
model_file <- model_file %>% str_replace_all("=>",">")
model_file <- model_file %>% str_replace_all("<=","<")

conditionalities_to_rewrite <-model_file %>% str_extract_all("\\w+(/|\\*)\\w+(<|>)\\d+(\\.\\d+)?") %>% reduce(c)

if(length(conditionalities_to_rewrite)>0){
conditionalities_table<- data.frame(expr = conditionalities_to_rewrite) %>% 
  mutate(
  A = str_remove(expr,"(<|>)\\d+(\\.\\d+)?"),
  B = str_remove(expr,"^\\w+[/\\*]\\w+(<|>)"),
  sign = str_replace(expr, "^.+(<|>).+$","\\1"),
  expr = str_replace_all(expr,'\\*',"\\\\*")) 

rewrite_cond <- function(A="A",B="B",sign=">"){
  if (sign== ">"){
    A_B <- paste0(A,"-",B)
    new_exp <- glue::glue("((({A_B})+abs({A_B}))/(2*({A_B})))")
  }
  
  if (sign== "<"){
    A_B <- paste0(A,"-",B)
    new_exp <- glue::glue("((abs({A_B})-({A_B}))/(-2*({A_B})))")
  }
  return(new_exp)
}

conditionalities_table$new_exp <- c(1:nrow(conditionalities_table)) %>%
  map_chr(~rewrite_cond(conditionalities_table$A[.x],
                        conditionalities_table$B[.x],
                        conditionalities_table$sign[.x]))

model_file <- model_file %>%
  str_replace_all(purrr::set_names(conditionalities_table$new_exp ,conditionalities_table$expr ) )
}

## variables extractions
all_var <- str_c(model_file,collapse = "+" ) %>% tresthor::get_variables_from_string()
missing_var <- setdiff(all_var, names(data_3me) )

if(length(missing_var)>0){
cat("\nThe following variables are present in the model but missing in the database:\n ")
cat(missing_var, sep = "\n")
error <- c(error,"missing variable in calib")
}
endogenous_var <- model_file %>% 
  str_extract("^.+=") %>% str_remove("=") %>% 
  set_names(c(1:length(model_file))) %>% 
  map(~tresthor::get_variables_from_string(.x)) %>% 
  ## Only keep the first instance from the list
  map(~.x[[1]]) %>% unlist()

if(is.null(elem)){
  coefficients_var <- c()
}else{coefficients_var <- elem_table$new_var_name}

exogenous_var <- setdiff(all_var, c(coefficients_var,endogenous_var))

out <- list(
    endo = endogenous_var,
    exo = exogenous_var,
    coef = coefficients_var,
    equations = model_file,
    data = data_3me,
    errors = error
)
}








