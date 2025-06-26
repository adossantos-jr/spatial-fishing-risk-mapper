## Mapping high-risk fishing areas through species vulnerability
This is an R routine built for quickly mapping high-risk fishing areas based on the ratio of vulnerable species caught in fishing points. This approach was originally intended for spatializing vulnerability in highly rich multispecies coastal fisheries using Productivity-Susceptibility Analysis (PSA) as a base for vulnerability categories. However, this routine can be applied to any type of fishery, and using any kind of vulnerability classification for species (such as IUCN Red List categories). As of right now, this routine applies a very simple triagulation method with various limitations. Geostatistical methods will be added in the future. 

### How to use
This routine is built in the R language. To use it, you must download and install the latest version of [R](https://www.r-project.org/), and the latest version of the [RStudio integrated development environment (IDE)](https://posit.co/download/rstudio-desktop/). You can then open the script (`spatial_vulnerable_species_ratio.R`) in RStudio.

#### Importing your data
##### Setting your working directory
The first step is setting your working directory. This directory is where the input data must be placed, and where the results will appear. This is done in this section (line 6):
```
setwd('your wd')
```
Where `your wd` must be replaced with a directory path. An example of a working directory path in Windows is:
```
setwd('C:/Users/alexandre/Documents/alexandre/maps')
```
To better understand working directories in R, a comprehensive guide can be found [here](https://intro2r.com/work-d.html).
##### Data structure and importing
This routine requires two simple data files: a vulnerability classification file and a species by sites file. Both must be .csv (comma-separated values) files. If you use software such as Microsoft Excel or Google Sheets to create your data frames, remember to convert them to .csv file before importing to R. The data frames are:

*The vulnerability classsification data* - The vulnerability classification data must contain two columns: a species column and a vulnerability category column, assigning a respective vulnerability category for each species. Species must be assigned one of three vulnerability categories: 'Low', 'Moderate' and 'High', since it is based on PSA (check the resources for more information). Due to the way that high-risk areas are defined, this can also be a binary classification of 'Low' and 'High' (If using IUCN Red List categories, for example, threatened species (>=VU) can be 'High', and non-threatened species can be 'Low'). For a template, see the test data (`test_vulnerability_class.csv`). 
Importing the vulnerabilibty category data is done in this section (line 10):
```
vuln_df = read.csv('test_vulnerability_class.csv')
```
This is defaulted to the name of the test data. You can change this name to the name of your own file, such as:
```
vuln_df = read.csv('my_iucn_classification.csv')
```
*The species by sites data*: The species by sites data is structured very much like matrices tradionally used in ecology, with species as columns and sites as rows. However, in this case, the first three columns of the species matrix must be `time`, `latitude` and `longitude` (see the test data for a template: test_species_data.csv). 
- The column `time` refers to any temporal classification of the fishing points (i. e. seasons, months, years). This column will be used to generate one map per each temporal classification (i. e. for seasons, one map per season), besides the main map. If there is no temporal classification in your data, this column must still exist, but it must be empty (filled with `NA` values). If `time` is empty, only the main map (your full study area with all inputed points) will be generated.
- The columns `latitude` and `longitude` are the respective latitude and longitude of fishing points in decimal degrees (fully numerical values; negative values for South and West hemispheres). If your coordinates are in another format, they must be converted to decimal. A useful coordinate converter from degrees/minutes/seconds to decimal can be found in the resources section. More information on coordinate systems can be found [here](https://www.uaf.edu/ces/publications/database/agriculture-livestock/understanding-mapping-systems.php). 
- The species columns can be filled with any kind of abundance/density/biomass/count metric. For a less biased analysis, some kind of standardization by fishing effort is recommended, such as Catch per Unit of Effort (CPUE) or Catch per Unit of Area (CPUA).

Importing the species data is done in this section (line 14):
```
species_matrix = read.csv('test_species_data.csv')
```
As with the vulnerability classification data, you must change `test_species_data.csv` to the filename of your .csv file. **The species names in the vulnerability classification matrix and the species matrix must be the same**.

### Adapting parameters to your study area/fishery
Here are instructions on how to state parameters designed to adapt the mapping to specific conditions. The following parameters are of a class which R calls `character`, so remember to always use quotation marks (either ' ' or " ") as in the default specifications in the script. If you don't use quotation marks, R will identify your inputs as an `object` instead and generate an error message saying the object was not found. The parameters are:

- National vs international area - Is your area international or contained within a country? This parameter is used adapt the level of geographical borders within the map. If your study area is international, country borders will be used. To specify this, simply set the following parameter to 'yes' instead of the default 'no' (line 19):
```
international_area = 'no'
```
- Country - If your study area is national, state borders will be used for you specified country. However, in order to do this, you need to set the name of your country (default is Brazil) in this section (line 24):
```
my_country = 'Brazil'
```
As long as the country name is in English and state border shapefiles can be retrieved through [Natural Earth](https://www.naturalearthdata.com/downloads/10m-cultural-vectors/), state borders will appear. 

**The following parameters are numbers, and of `numeric` class instead of `character`. Therefore, no quotation marks should be used**:

-  Resolution of bathymetry data - This rountine retrieves bathymety data from the U. S. National Oceanic and Atmospheric Administration (NOAA) servers. The default resolution of bathymetric data is 3 minutes (roughly 1.8 km/1.5 miles). Smaller resolutions will be more precise but may take longer to process. To change it, simply change the number `5` in this section (line 28):
```
my_bathy_res = 3 
``` 
- Vulnerable Species Ratio thresholds - The default thresholds are 0 from 0.25 for 'Low', 0.25 to 0.5 for 'Moderate', and 0.5 to 1 for 'High'. To change it, you can simply change the values in this section (line 32):
```
my_thresholds = c(0, 0.25, 0.5, 1)
```
Though beware that the limits (0 and 1) should not be changed; only the values in the middle.
- Map resolution - Finally, you can select the desired resolution of your maps in dots per inches (DPI). Higher DPI will result in a higher resolution map, but may take longer to process. To change it, simply change the number of the default `600` (line 36): 
```
my_dpi = 600
````
**And done!** Now, you can press Ctrl + A and then Ctrl + Enter to run all the script and get the results. A map with a delimited high-risk fishing area will appear in your working directory, alongside a .csv file with the Vulnerable Species Ratio value for each point. If temporal classifications are present, a figure with maps by temporal classification will also be generated.

### Limitations
Since this method of defining high-risk fishing areas is based on a simple triagulation of high-risk points, the spatialization itself may fail/not be interpretable if:
- **Low spatial autocorrelation of vulnerability in all conditions**, that is, points next to each other are in no way more similar to each other than to other points regarding the Vulnerable Species Ratio. This can be due to the relation of the spatial scale with density of points (points too spread across a wide scale or too concentrated at a small scale), or due to the complexity of the fishery/ecosystem/community itself. In short, this triagulation method does not account well for nuances in the spatial distribution of vulnerability. Geostatistical techniques are needed to properly spatialize vulnerability in these conditions.

- **Estuarine or inland waters**, since this framework is focused on marine areas. A different mapping framework would be needed to spatialize vulnerability in continental waters.

Nevertheless, the information of Vulnerable Species Ratio is still valid and can be useful in these conditions. So, even if mapping is unviable using this method, the resulting .csv file can still be of use.

### Resources
- [A coordinate converter](https://www.fcc.gov/media/radio/dms-decimal)
- [PSA Web Application for single species](https://nmfs-ost.github.io/noaa-fit/PSA) 
- [PSA routine for multiple species at once](https://github.com/adossantos-jr/psa-multispecies)
- [IUCN Red List R API](https://github.com/ropensci/rredlist)
- [Natural Earth R API](https://github.com/ropensci/rnaturalearth)
  
