### Commodities: c4
names_commodities <- rbind(
c('Good 1','c001'),
c('Good 2','c002')
) %>%
  as.data.frame() %>% rename(name = V1,code = V2)

### Sectors: s4
names_sectors <- rbind(
c('Sector 1','S001'),
c('Sector 2','S002')
) %>%
  as.data.frame() %>% rename(name = V1,code = V2)
