# Calving Season Habitat Selection of Moose in Southwest Alaska

*Authors*:
Amanda Droghini, Timm W. Nawrocki, Alaska Center for Conservation Science, University of Alaska Anchorage

## Project Overview

This repository includes scripts that were used in the scientific article, [*Variation in habitat selection among individuals differs by maternal status for moose in a region with low calf survival*](https://doi.org/10.1002/ecs2.70069), published in the journal Ecosphere in 2024. The scripts process GPS telemetry data, prepare geospatial covariates, analyze selection patterns among female moose in maternal and non-maternal group, and plot variation among individuals between both groups along a relative unitless scale. 

The objective of these analyses was to compare variation in habitat selection among individuals of maternal and nonmaternal female moose during the calving season. We hypothesized that, when compared to nonmaternal females, maternal females would exhibit a greater range of variation among individuals. Our hypothesis was driven by existing research on large herbivores' responses to risk-forage trade-offs, and the factors (such as maternal status) that are expected to influence changes in responses among individuals.

Our predictive models had high levels of accuracy (>75%) based both on independent test partitions of a nested cross-validation and on independent very high frequency (VHF) location data, each including spatial and temporal replication. We found that both groups of females preferred areas where primary forage species were abundant, diverse, and within foraging height. While habitat selected by the maternal group overlapped with habitat selected by the nonmaternal group, maternal individuals were less consistent in their habitat selection than nonmaternal individuals. These findings suggest that the range of trade-off responses exhibited by maternal females exist along a continuum, the poles of which are 'responses that are no different than those of nonmaternal females' and 'responses that diverge substantially from those of nonmaternal females'.

This project was a collaboration between the Alaska Center for Conservation Science and the Alaska Department of Fish and Game.

## Getting Started

The installation of R, ArcGIS Pro bundled with Python, and an independent Python with the dependencies listed below is required to execute the full suite of scripts included in this repository. The header of each script indicates in what system the script should be executed.

Folders and scripts are numbered in order of execution, except those that contain functions (folders starting with "package_"). 

### Prerequisites
1. ArcGIS Pro 2.5.2+
   1. Python 3.6.9+
2. R 4.0.0+
   1. adehabitatLT 0.3.25+ 
   2. ctmm 0.5.10+
   3. lubridate 1.7.8+
   4. move 4.0.0+
   5. plyr 1.8.6+
   6. raster 3.1.5+
   7. rgdal 1.4.8+
   8. readxl 1.3.1+
   9. sf 0.9.3+
   10. tidyverse 1.3.0+
   11. tlocoh 1.40.7+
   12. zoo 1.8.8+
3. R Studio 1.3.9+
4. Python 3.8.8+ (Anaconda 2021.05 or later distribution)
   1. scikit-learn 0.24.2+

## Credits

### Authors
* **Amanda Droghini** - *Alaska Center for Conservation Science, University of Alaska Anchorage*
* **Timm W. Nawrocki** - *Alaska Center for Conservation Science, University of Alaska Anchorage*

### Usage Requirements
Use of the scripts included in this repository should be cited as follows:

Droghini, A., T.W. Nawrocki, J.B. Stetz, P.A. Schuette, A.R. Aderman, and K.E. Colson. 2024. Variation in habitat selection among individuals differs by maternal status for moose in a region with low calf survival. Ecosphere 15(11):e70069. [https://doi.org/10.1002/ecs2.70069](https://doi.org/10.1002/ecs2.70069).

### Citations
We referenced the following for the scripts that calculate topographic indices:

Evans J.S., J. Oakleaf, S. A. Cushman. 2014. An ArcGIS Toolbox for Surface Gradient and Geomorphometric Modeling, version 2.0-0. Available: https://github.com/jeffreyevans/GradientMetrics

### License

This project is provided under the GNU General Public License v3.0. It is free to use and modify in part or in whole.
