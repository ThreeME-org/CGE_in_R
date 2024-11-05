contrib_longformat <- function (data, var1, var2, indicator = "rel.diff", scenar = scenarios, 
          check_digit = 3, neg.value = NULL) 
{
  if (is.null(scenar)) {
    scenar = "baseline"
  }
  if (length(scenar) > 2) {
    stop(message = "Indicate a maximum of two scenarios.\n")
  }
  if (length(scenar) == 2 & !"baseline" %in% scenar) {
    stop(message = "If two scenarios are given, one must be the ' 'baseline' scenario.\n")
  }
  
  if(length(scenar) == 2 & "baseline" %in% scenar){
    ## long format output to old version -> need to be changed in the future
    data.temps <- data %>% filter(scenario == "baseline") %>% mutate(baseline = values) %>% 
      select(-values_ref,-values,-scenario,-index_scen) %>%
      left_join(data %>% filter(scenario == setdiff(scenar, "baseline")) %>% 
                  mutate(!!paste0(setdiff(scenar, "baseline")) := values) %>%
                  select(-values_ref,-values,-scenario,-index_scen) ,
                by = c("year","variable","commodity","sector"))
    data <- data.temps
  }
  
  if (prod(scenar %in% names(data)) == 0) {
    not_found <- setdiff(scenar, names(data))
    stop(message = paste0("The '", not_found, "' scenario was not found in the database.\n"))
  }
  

  
  filtered.var <- c(var1, var2)
  data.in <- data %>% dplyr::filter(variable %in% filtered.var)
  data.w_baseline <- data.in %>% dplyr::select(variable, year, 
                                               baseline) %>% tidyr::pivot_wider(names_from = variable, 
                                                                                values_from = baseline) %>% dplyr::mutate_at(.funs = list(weight = ~./get(var1)), 
                                                                                                                             .vars = var2) %>% dplyr::select(year, contains("_weight"))
  if (!is.null(neg.value)) {
    data.w_baseline <- data.w_baseline %>% dplyr::mutate_at(str_c(neg.value, 
                                                                  "_weight"), ~((-1) * .x))
  }
  if (length(scenar) == 1) {
    data.contrib.1 <- data.in %>% dplyr::mutate(scenario = .[, 
                                                             scenar]) %>% dplyr::select(variable, year, scenario) %>% 
      tidyr::pivot_wider(names_from = variable, values_from = c(scenario))
    data.contrib.2 <- data.contrib.1
  }
  else {
    shock_scenario <- setdiff(scenar, "baseline")
    data.contrib.1 <- data.in %>% dplyr::mutate(scenario = .[, 
                                                             str_c(shock_scenario)] - .[, "baseline"]) %>% dplyr::select(variable, 
                                                                                                                         year, scenario) %>% tidyr::pivot_wider(names_from = variable, 
                                                                                                                                                                values_from = scenario)
    data.contrib.2 <- data.in %>% dplyr::mutate(scenario = .[, 
                                                             str_c(shock_scenario)]/.[, "baseline"] - 1) %>% dplyr::select(variable, 
                                                                                                                           year, scenario) %>% tidyr::pivot_wider(names_from = variable, 
                                                                                                                                                                  values_from = scenario)
  }
  if (indicator == "rel.diff" & indicator != "gr.diff" & indicator != 
      "share") {
    if (!is.null(neg.value)) {
      data.contrib.1 <- data.contrib.1 %>% dplyr::mutate_at(neg.value, 
                                                            ~((-1) * .x))
    }
    weight_check <- data.contrib.1 %>% dplyr::mutate_at(.funs = list(weight = ~./get(var1)), 
                                                        .vars = var2) %>% dplyr::select(year, contains("_weight")) %>% 
      as.data.frame() %>% `colnames<-`(c("year", var2)) %>% 
      tidyr::pivot_longer(names_to = "variable", values_to = "value", 
                          -year) %>% tidyr::pivot_wider(names_from = variable, 
                                                        values_from = value) %>% dplyr::filter(year == max(year)) %>% 
      dplyr::select(-year) %>% rowSums()
    data.contrib.3 <- data.contrib.2 %>% dplyr::select(-all_of(var1))
    data.contrib <- (dplyr::select(data.contrib.3, year, 
                                   all_of(var2))[-1] * dplyr::select(data.w_baseline, 
                                                                     year, all_of(str_c(var2, "_weight")))[-1]) %>% cbind(year = data.contrib.2[1], 
                                                                                                                          .) %>% as.data.frame() %>% tidyr::pivot_longer(names_to = "variable", 
                                                                                                                                                                         values_to = "value", -year)
  }
  else {
    if (indicator == "gr.diff" & indicator != "share") {
      if (length(scenar) == 1) {
        data.gr_sc <- data.in %>% dplyr::group_by(variable) %>% 
          dplyr::mutate(lag.value = get(scenar) - dplyr::lag(get(scenar), 
                                                             n = 1, default = NA), value = ((lag.value/get(scenar)))) %>% 
          dplyr::select(year, variable, value) %>% tidyr::pivot_wider(names_from = variable, 
                                                                      values_from = value)
        df <- (dplyr::select(data.gr_sc, year, all_of(var2))[-1] * 
                 data.w_baseline[-1])
        data.contrib <- cbind(year = data.gr_sc[1], df) %>% 
          as.data.frame() %>% tidyr::pivot_longer(names_to = "variable", 
                                                  values_to = "value", -year)
      }
      else {
        shock_scenario <- setdiff(scenar, "baseline")
        data.gr_baseline <- data.in %>% dplyr::group_by(variable) %>% 
          dplyr::mutate(lag.value = baseline - dplyr::lag(baseline, 
                                                          n = 1, default = NA), value = ((lag.value/baseline))) %>% 
          dplyr::select(year, variable, value) %>% tidyr::pivot_wider(names_from = variable, 
                                                                      values_from = value)
        data.gr_sc <- data.in %>% dplyr::group_by(variable) %>% 
          dplyr::mutate(lag.value = get(shock_scenario) - 
                          dplyr::lag(get(shock_scenario), n = 1, default = NA), 
                        value = ((lag.value/get(shock_scenario)))) %>% 
          dplyr::select(year, variable, value) %>% tidyr::pivot_wider(names_from = variable, 
                                                                      values_from = value)
        df <- (dplyr::select(data.gr_sc, year, all_of(var2))[-1] * 
                 data.w_baseline[-1]) - (dplyr::select(data.gr_baseline, 
                                                       year, all_of(var2))[-1] * data.w_baseline[-1])
        data.contrib <- cbind(year = data.gr_baseline[1], 
                              df) %>% as.data.frame() %>% tidyr::pivot_longer(names_to = "variable", 
                                                                              values_to = "value", -year)
      }
      weight_check <- data.w_baseline %>% dplyr::filter(year == 
                                                          max(year)) %>% dplyr::select(-year) %>% rowSums()
    }
    else {
      if (indicator == "share") {
        data.contrib <- data.in %>% dplyr::select(variable, 
                                                  year, scenar) %>% tidyr::pivot_wider(names_from = variable, 
                                                                                       values_from = scenar) %>% dplyr::mutate_at(.funs = list(weight = ~./get(var1)), 
                                                                                                                                  .vars = var2) %>% dplyr::select(year, contains("_weight")) %>% 
          `colnames<-`(c("year", var2)) %>% tidyr::pivot_longer(names_to = "variable", 
                                                                values_to = "value", -year)
      }
      else {
        data.contrib <- data.contrib.1 %>% as.data.frame() %>% 
          dplyr::select(-var1, year, var2) %>% `colnames<-`(c("year", 
                                                              var2)) %>% tidyr::pivot_longer(names_to = "variable", 
                                                                                             values_to = "value", -year)
      }
      weight_check <- data.w_baseline %>% dplyr::filter(year == 
                                                          max(year)) %>% dplyr::select(-year) %>% rowSums()
    }
  }
  if (round(weight_check, check_digit) != 1) {
    cat(str_c("Weights are not summing to one: Try again !\n (difference of: ", 
              100 * (round(weight_check, check_digit) - 1), "%)"))
  }
  else {
    cat("Weights sum to one: Good job !\n")
  }
  data.contrib
}

contrib.sub_longformat <- function (data, var1, group_type = "sector", scenar = scenario_to_analyse, 
          check_digit = 3) 
{
  if (is.null(scenar)) {
    scenar = "baseline"
  }
  if (length(scenar) > 2) {
    stop(message = "Indicate a maximum of two scenarios.\n")
  }
  if (length(scenar) == 2 & !"baseline" %in% scenar) {
    stop(message = "If two scenarios are given, one must be the ' 'baseline' scenario.\n")
  }
  
  if(length(scenar) == 2 & "baseline" %in% scenar){
    ## long format output to old version -> need to be changed in the future
    data.temps <- data %>% filter(scenario == "baseline") %>% mutate(baseline = values) %>% 
      select(-values_ref,-values,-scenario,-index_scen) %>%
      left_join(data %>% filter(scenario == setdiff(scenar, "baseline")) %>% 
                  mutate(!!paste0(setdiff(scenar, "baseline")) := values) %>%
                  select(-values_ref,-values,-scenario,-index_scen) ,
                by = c("year","variable","commodity","sector"))
    data <- data.temps
  }
  
  if (prod(scenar %in% names(data)) == 0) {
    not_found <- setdiff(scenar, names(data))
    stop(message = paste0("The '", not_found, "' scenario was not found in the database.\n"))
  }
  if (is.null(check_digit)) {
    check_digit = 3
  }
  if (length(scenar) == 2) {
    contrib_ecart = TRUE
  }
  else {
    contrib_ecart = FALSE
  }
  if (is.character(group_type) == FALSE) {
    stop(message = " Argument group_type must be a character string starting with s for sectors or c for commodities.\n")
  }
  else {
    group <- toupper(str_replace(group_type, "^(.).*$", "\\1"))
  }
  if (!group %in% c("S", "C")) {
    stop(message = " Argument group_type must be a character string starting with s for sectors or c for commodities.\n")
  }
  if (group == "S") {
    division_type = "Sector"
  }
  if (group == "C") {
    division_type = "Commodity"
  }
  var_vec <- unique(data$variable)
  liste_var <- var_vec[grep(paste0("^", var1, "_", group, "[A-Z0-9]{3}$"), 
                            var_vec)]
  filtered.var <- dplyr::filter(data, variable %in% liste_var)
  filtered.val <- unique(filtered.var$variable[filtered.var$baseline != 
                                                 0])
  if (length(liste_var) == 0) {
    liste_var
    stop(message = "No variables matching the variable and the group_type were found.\n")
  }
  data.contrib.0 <- data %>% dplyr::filter(variable %in% c(var1, 
                                                           filtered.val))
  data.contrib.lbl <- data %>% dplyr::filter(variable %in% 
                                               c(var1, filtered.val)) %>% select(variable, year, commodity, 
                                                                                 sector)
  if (group == "C") {
    data.contrib.lbl <- select(data.contrib.lbl, -sector) %>% 
      `colnames<-`(c("variable", "year", "label"))
  }
  if (group == "S") {
    data.contrib.lbl <- select(data.contrib.lbl, -commodity) %>% 
      `colnames<-`(c("variable", "year", "label"))
  }
  data.w_baseline <- data.contrib.0 %>% select(variable, year, 
                                               baseline) %>% pivot_wider(names_from = variable, values_from = baseline) %>% 
    mutate_at(.funs = list(w = ~./get(var1)), .vars = filtered.val) %>% 
    select(year, contains("_w"))
  if (length(scenar) == 1) {
    data.contrib.1 <- data.contrib.0 %>% mutate(scenario = .[, 
                                                             scenar]) %>% select(variable, year, scenario) %>% 
      pivot_wider(names_from = variable, values_from = c(scenario))
    data.contrib <- data.contrib.1 %>% mutate_at(.funs = list(w = ~./get(var1)), 
                                                 .vars = filtered.val) %>% select(year, contains("_w"))
    weight_check <- round(rowSums(data.contrib[10, ]) - data.contrib[10, 
                                                                     1], check_digit)
    data.contrib <- data.contrib %>% as.data.frame() %>% 
      `colnames<-`(c("year", unique(filtered.val))) %>% 
      pivot_longer(names_to = "variable", values_to = "value", 
                   -year)
    data.contrib <- left_join(data.contrib.lbl, data.contrib, 
                              by = c("variable", "year"))
  }
  else {
    shock_scenario <- setdiff(scenar, "baseline")
    data.contrib.1 <- data.contrib.0 %>% mutate(scenario = .[, 
                                                             str_c(shock_scenario)] - .[, "baseline"]) %>% select(variable, 
                                                                                                                  year, scenario) %>% pivot_wider(names_from = variable, 
                                                                                                                                                  values_from = scenario)
    data.contrib.2 <- data.contrib.0 %>% mutate(scenario = .[, 
                                                             str_c(shock_scenario)]/.[, "baseline"] - 1) %>% select(variable, 
                                                                                                                    year, scenario) %>% pivot_wider(names_from = variable, 
                                                                                                                                                    values_from = scenario)
    data.contrib <- data.contrib.1 %>% mutate_at(.funs = list(w = ~./get(var1)), 
                                                 .vars = filtered.val) %>% select(year, contains("_w"))
    weight_check <- round(rowSums(data.contrib[10, ]) - data.contrib[10, 
                                                                     1], check_digit)
    data.contrib.3 <- data.contrib.2 %>% select(-var1)
    data.contrib.4 <- (data.contrib.3[-1] * data.w_baseline[-1]) %>% 
      cbind(year = data.contrib.3[1], select(data.contrib.2, 
                                             var1), .) %>% as.data.frame() %>% pivot_longer(names_to = "variable", 
                                                                                            values_to = "value", -year)
    data.contrib <- left_join(data.contrib.lbl, data.contrib.4, 
                              by = c("variable", "year"))
  }
  if (weight_check != 1) {
    cat("Weights are not summing to one: Try again !\n")
  }
  else {
    cat("Weights sum to one: Good job !\n")
  }
  data.contrib
}

contrib_calc <- function(...){return(contrib_longformat(...))}