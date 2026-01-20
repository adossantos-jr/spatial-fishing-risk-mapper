## Mapping high-risk fishing areas through vulnerable species proportion
This is a shiny app built for quickly mapping high-risk fishing areas based on the ratio of vulnerable species caught in fishing points. This approach was originally intended for viewing vulnerability spatially in highly rich multispecies coastal fisheries using Productivity-Susceptibility Analysis (PSA) for vulnerability classifications. However, this routine can be applied to any type of fishery, and using any kind of vulnerability classification for species (such as IUCN Red List categories). As of right now, this routine applies a very simple triagulation method with various limitations. Geostatistical methods will be added in the future. 

### How to use
This app is built in the R language and runs in your local R server. To use it, you must download and install the latest version of [R](https://www.r-project.org/), and the latest version of the [RStudio integrated development environment (IDE)](https://posit.co/download/rstudio-desktop/). You can then download the [R script file](https://github.com/adossantos-jr/spatial-fishing-risk-mapper/blob/main/spatial_fishing_risk_mapper.R) and open it in RStudio.

#### Importing your data
##### Data structure and importing
This routine requires two simple data files: a vulnerability classification file and a species by sites file. Both must be .csv (comma-separated values) files. If you use software such as MS Excel or Google Sheets to create your data frames, remember to convert them to a .csv file before importing to R. The data frames are:

*The vulnerability classsification data* - The vulnerability classification data must contain two columns: a species column and a vulnerability category column, assigning a respective vulnerability category for each species. Species must be assigned one of three vulnerability categories: 'Low', 'Moderate' and 'High', since it is based on PSA (check the resources for more information). Due to the way that high-risk areas are defined, this can also be a binary classification of 'Low' and 'High' (If using IUCN Red List categories, for example, threatened species (>=VU) can be 'High', and non-threatened species can be 'Low'). For a template, see the [test data](https://github.com/adossantos-jr/spatial-fishing-risk-mapper/blob/main/test_vulnerability_class.csv). 

*The species by sites data*: The species by sites data is structured very much like a traditional ecological matrix, with species as columns and sites as rows. However, in this case, the first three columns of the species matrix must be `time`, `latitude` and `longitude`. See the [test data](https://github.com/adossantos-jr/spatial-fishing-risk-mapper/blob/main/test_species_data.csv) for a template  

- The column `time` refers to any temporal classification of the fishing points (i. e. seasons, months, years). This column will be used to generate one map per each temporal classification (i. e. for seasons, one map per season), besides the main map. If there is no temporal classification in your data, this column must still exist, but it must be empty (filled with `NA` values). If `time` is empty, only the main map (your full study area with all inputed points) will be generated.
- 
- The columns `latitude` and `longitude` are the respective latitude and longitude of fishing points in decimal degrees (fully numerical values; negative values for South and West hemispheres). If your coordinates are in another format, they must be converted to decimal. A useful coordinate converter from degrees/minutes/seconds to decimal can be found in the resources section. More information on coordinate systems can be found [here](https://www.uaf.edu/ces/publications/database/agriculture-livestock/understanding-mapping-systems.php).
- 
- The species columns can be filled with any kind of abundance/density/biomass/count metric.
- **The species names in the vulnerability classification matrix and the species matrix must be the same**.

### Running the App
After opening the [script](https://github.com/adossantos-jr/spatial-fishing-risk-mapper/blob/main/spatial_fishing_risk_mapper.R) in RStudio, press Ctrl + A and then Ctrl + Enter to run the App. All the required packages will be installed/loaded automatically. When you first run this app, the automatic package installation may take up to several minutes depending on your internet connection and what packagews you already have installed. After that, it should take a few seconds. 

### Adapting parameters to your study area/fishery
Here are instructions on how to fill parameters designed to adapt the mapping to specific conditions. 

- National vs international area - Is your area international or contained within a country? This parameter is used adapt the level of geographical borders within the map. If your study area is international, country borders will be used. 
- Country - If your study area is national, state borders will be used for you specified country. However, in order to do this, you need to set the name of your country (default is Brazil). As long as the country name is in English and state border shapefiles can be retrieved through [Natural Earth](https://www.naturalearthdata.com/downloads/10m-cultural-vectors/), state borders will appear. 
- Resolution of bathymetry data - This rountine retrieves bathymety data from the U. S. National Oceanic and Atmospheric Administration (NOAA) servers. The default resolution of bathymetric data is 3 minutes (roughly 1.8 km/1.5 miles). Smaller resolutions will be more precise but may take longer to process. 
- Maximum an minimum depth limits you want to visualize on the map - Here is where you set the maximum and minimum depths for mapping the bathymetry. Since the test data is in a coastal area, defaults are set to `0` for minimum depth and `-150` for maximum depth. Adjust it according to your study area (line 32 and 33):
- Vulnerable Species Ratio thresholds - The default thresholds are 0 from 0.25 for 'Low', 0.25 to 0.5 for 'Moderate', and 0.5 to 1 for 'High'. Remember that this is a proportion, ranging from 0 (no vulnerable species) to 1 (all vulnerable species).
- Map resolution - Finally, you can select the desired resolution of your maps in dots per inches (DPI). Higher DPI will result in a higher resolution map, but may take longer to process.
  
Finally, scroll down and click the Generate Map & Results button. **And done!** A map with a delimited high-risk fishing area will appear in your working directory, alongside a .csv file with the Vulnerable Species Ratio value for each point. If temporal classifications are present, a figure with maps by temporal classification will also be generated. The output in the UI should look like this:

<img width="903" height="641" alt="ui_spatial" src="https://github.com/user-attachments/assets/0ba9cdc5-a9a2-4553-8362-31732017902d" />


### Limitations
Since this method of defining high-risk fishing areas is based on a simple triagulation of high-risk points, the mapping itself may not be interpretable if:
- **Low spatial autocorrelation of vulnerability in all conditions**, that is, points next to each other are in no way more similar to each other than to other points regarding the Vulnerable Species Ratio. This can be due to the relation of the spatial scale with density of points (points too spread across a wide scale or too concentrated at a small scale), or due to the complexity of the fishery/ecosystem/community itself. In short, this triagulation method does not account well for nuances in the spatial distribution of vulnerability. Geostatistical techniques are needed to properly map vulnerability in these conditions.

- **Estuarine or inland waters**, since this framework is focused on marine areas. A different mapping framework would be needed to map vulnerability in continental waters.

Nevertheless, the information of Vulnerable Species Ratio is still valid and can be useful in these conditions. So, even if mapping is unviable using this method, the resulting .csv file may still be useful.

### Resources
- [A coordinate converter](https://www.fcc.gov/media/radio/dms-decimal)
- [PSA Web Application for single species](https://nmfs-ost.github.io/noaa-fit/PSA) 
- [PSA routine for multiple species at once](https://github.com/adossantos-jr/psa-multispecies)
- [IUCN Red List R API](https://github.com/ropensci/rredlist)
- [Natural Earth R API](https://github.com/ropensci/rnaturalearth)
  
