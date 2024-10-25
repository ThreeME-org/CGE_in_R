update_data_merge <- function(old_data , new_data, by_join_var = "year"){
## Add check that same length
## add foolproof with differing length

## add check that by join var is common

if(nrow(old_data) == nrow(new_data) ){

var_to_update = setdiff(names(new_data), by_join_var)

res <- old_data %>% select(-any_of(var_to_update) ) %>%
full_join(new_data, by = by_join_var)



}else{
    cat("Function doesnt work yet with data.frames of differing length")
    res <- old_data
}

return(res)

}