# Mapping spatial Vulnerable Species Ratio 
# for more information, go to https://github.com/adossantos-jr/spatial-fishing-risk-mapper

# Getting your working directory
if (!require("rstudioapi")) install.packages("rstudioapi")
setwd(dirname(rstudioapi::getActiveDocumentContext()$path)) 

# Importing the species and vulnerability category data

vuln_df = read.csv('test_vulnerability_class.csv')

# Importing the species data 

species_data = read.csv('test_species_data.csv')

# Is your study area national or international?
# If yes, state 'yes'

international_area = 'no'

# If your study area is national
# What is the name of your country (in English)?

my_country = 'Brazil'

# Select desired resolution for bathymetry data (in minutes)

my_bathy_res = 1

# Select the miminum and maximum depth you want to visualize on your map
  
  max_depth = -150
  min_depth = 0

# Set your desired thresholds 

my_thresholds = c(0, 0.25, 0.5, 1)

# Select desired DPI for maps

my_dpi = 600

# Now press Ctrl + A, then Ctrl + Enter to run the script
# and get the maps!

if (!require("pacman")) install.packages("pacman")

pacman::p_load(ggplot2, rnaturalearth, sf, terra, raster,
               tidyterra, ggalt, ggspatial, ggpmisc, tidyterra, 
               marmap, ggrepel, rnaturalearthdata, sjmisc)

if (!require("rnarutalearthhires")) remotes::install_github("ropensci/rnaturalearthhires")

# Importing bathymetry shapefile

lon1 = min(species_data$longitude) + min(species_data$longitude)*.01 
lon2 = max(species_data$longitude) - max(species_data$longitude)*.01
lat1 = min(species_data$latitude) + min(species_data$latitude)*.01
lat2 = max(species_data$latitude) - max(species_data$latitude)*.01

bathy = getNOAA.bathy(lon1 = lon1, 
                      lon2 = lon2,
                      lat1 = lat1,
                      lat2 = lat2,
                      res = my_bathy_res, keep = F) %>%
  as.xyz() %>%
  subset(V3 > max_depth & V3 < min_depth) %>%
  rasterFromXYZ() %>%
  rast()

# Calculating the vulnerable species ratio

vul_map = data.frame(setNames(vuln_df$vul_category, vuln_df$species))

vulclass_df = species_data[,-c(1:3)]
colnames(vulclass_df) = vul_map$setNames.vuln_df.vul_category..vuln_df.species.

vulclass_df = as.data.frame(sapply(split.default(vulclass_df, 
                                  names(vulclass_df)), 
                                   rowSums))
vulclass_df[is.na(vulclass_df)] = 0

if('Moderate' %in% colnames(vulclass_df) == 'TRUE') {
vsr = ((vulclass_df$Moderate + vulclass_df$High) + 1)/(rowSums(vulclass_df) + 1)
} else {vsr = ((vulclass_df$High) + 1)/(rowSums(vulclass_df) + 1)
}

vsr_cut = cut(vsr, breaks = my_thresholds)

# Mapping

if (international_area == 'no') {
  
  geo_shp = ne_states(my_country, returnclass = 'sf')
  
}else{
  geo_shp = ne_countries(returnclass = 'sf') }

vsr_map = 
  ggplot(species_data)+
  geom_spatraster_contour_text(data = bathy)+
  geom_encircle(data = species_data, 
                aes(x = longitude, y = latitude, fill = vsr_cut),
                s_shape = 1,
                alpha = 0.4, spread = 0.0001, 
                color = 'transparent')+
  geom_sf(data = geo_shp) +
  coord_sf(xlim = c(lon1, lon2),
           ylim = c(lat1, lat2))+
  labs(x = '', y = '', fill = 'Vulnerable Species Ratio')+
  theme_bw()+
  scale_fill_manual(values = c('forestgreen', 'yellow', 'red3'))+
  theme(legend.position = 'bottom',
        axis.text.x = element_text(angle = 60, vjust = .6,
                                   color = 'black'),
        axis.text.y = element_text(angle = 60, hjust = .6, 
                                   color = 'black'))+
  guides(fill = guide_colorsteps(barheight = 0.5, 
                                 barwidth = 10,
                                 title.position = 'bottom', 
                                 show.limits = T))

if(all_na(species_data$time) == 'FALSE'){
  
  vsr_by_time = 
    vsr_map + facet_wrap(~time)
  
  ggsave(vsr_map,
         filename = 'vuln_species_ratio.png',
         h = 25/4,
         w = 25/4,
         dpi = my_dpi)
  
  ggsave(vsr_by_time,
         filename = 'vuln_species_ratio_by_time.png',
         h = 25/4,
         w = 25/4,
         dpi = my_dpi)
  
  data.frame(
    time = species_data$time,
    latitude = species_data$latitude,
    longitude = species_data$longitude,
    vulnerable_species_ratio = vsr) %>%
    write.csv('vulnerable_species_ratio_result.csv')
  
} else {
  
  data.frame(latitude = species_data$latitude,
    longitude = species_data$longitude,
    vulnerable_species_ratio = vsr) %>%
    write.csv('vulnerable_species_ratio_result.csv')
  
  ggsave(vsr_map,
         filename = 'vul_species_ratio.png', 
         h = 25/4,
         w = 25/4,
         dpi = my_dpi)
}

print('Done! check your working directory for results')




