### Commodities: c4
names_commodities <- rbind(
c('Industry','cind'),
c('Transport','ctrp'),
c('Services','cser'),
c('Energy','cenj'),
c('Industry','C001'),
c('Transport','C002'),
c('Services','C003'),
c('Energy','C004')
) %>%
  as.data.frame() %>% rename(name = V1,code = V2)

### Sectors: s4
names_sectors <- rbind(
c('Industry','sind'),
c('Transport','strp'),
c('Services','sser'),
c('Energy','senj'),
c('Industry','S001'),
c('Transport','S002'),
c('Services','S003'),
c('Energy','S004')
) %>%
  as.data.frame() %>% rename(name = V1,code = V2)
