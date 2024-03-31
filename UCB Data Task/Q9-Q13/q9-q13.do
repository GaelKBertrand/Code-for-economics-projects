* clear all the current workspace work
clear all
* Logging
log using "/Users/gaelk.bertrand/Desktop/UCB/clean_data/q9-q13.log", replace

/*
	Filename: q9-q13.do
	Description: Stata do-file for data test
	Author: Bertrand Kwibuka
	Date: [03/20/2024]

	** Notes before executing **:

	1. Navigate to all places in the code and change the directory paths. 
	You should have your own directory paths written correctly before 
	running the code. 

	2. If you are running a windows machine, remember that the directory
	paths use "\" instead of "/" like in MacOs machines.
	
*/

* CODE STARTS HERE *

* Set up working directory
cd "/Users/gaelk.bertrand/Desktop/UCB"

* Install dependencies 
ssc install ietoolkit
ssc install reghdfe
ssc install ftools
ssc install outreg2

* Load data
use "/Users/gaelk.bertrand/Desktop/UCB/clean_data/merged_data.dta", clear


**** Q9. BALANCE TABLES AND TESTS ****

/* Convert necessary categorical variables to be used into binary variables first 
tabulate walls, generate(walls_)
rename walls_1 walls_SticksPalm
rename walls_2 walls_Mudbrick
rename walls_3 walls_BricksBadConditions
rename walls_4 walls_Ciment

tabulate roof, generate(roof_)
rename roof_1 roof_ThatchStraw
rename roof_2 roof_SheetIron
*/

* Directory assignment 
local outfld "/Users/gaelk.bertrand/Desktop/UCB/clean_data/"

* Produce the balance table using the 'ieltoolkit' from the world bank for simplicity
iebaltab  dist_city_center dist_commune_buildings dist_public_schools dist_roads walls roof age_prop sex_prop, groupvar (reduction_pct) savecsv("`outfld'/balance.csv")




**** Q10. REGRESSIONS  ****

use "/Users/gaelk.bertrand/Desktop/UCB/clean_data/merged_data.dta", clear

* Run regression for all properties
regress visit_post_carto pct50 pct67 pct83

* Export regression results for all properties
outreg2 using "/Users/gaelk.bertrand/Desktop/UCB/clean_data/regression_results_q10.xlsx", replace ctitle("All Properties")

* Subset data for properties with constant bonus
keep if bonus_constant == 1

* Run regression for properties with constant bonus
regress visit_post_carto pct50 pct67 pct83 

* Append regression results for properties with constant bonus to the same file
outreg2 using "/Users/gaelk.bertrand/Desktop/UCB/clean_data/regression_results_q10.xlsx", append ctitle("Constant Bonus")

* Subset data for properties with proportional bonus
use "/Users/gaelk.bertrand/Desktop/UCB/clean_data/merged_data.dta", clear
keep if bonus_prop == 1

* Run regression for properties with proportional bonus
regress visit_post_carto pct50 pct67 pct83

* Append regression results for properties with proportional bonus to the same file
outreg2 using "/Users/gaelk.bertrand/Desktop/UCB/clean_data/regression_results_q10.xlsx", append ctitle("Proportional Bonus") excel dec(3) bdec(3) sdec(3) se




**** Q11.REGRESSIONS ****

*Load data again
use "/Users/gaelk.bertrand/Desktop/UCB/clean_data/merged_data.dta", clear
global xlist pct50 pct67 pct83

* Run regression for all properties with polygon fixed effects
regress visit_post_carto $xlist i.a7
	** From here you will notice that some a7 are being dropped, so check for multicollinearity error
vif
	** If vif > 5 and 10, then yes, there is multicollinearity, so proceed below:

* Run regression for all properties with polygon fixed effects
reghdfe visit_post_carto $xlist, absorb(a7) vce(robust)

* Export regression results for all properties with polygon fixed effects
outreg2 using "/Users/gaelk.bertrand/Desktop/UCB/clean_data/regression_results_q11.xlsx", replace excel ctitle("All Properties with Polygon FE")

* Subset data for properties with constant bonus
keep if bonus_constant == 1

* Run regression for properties with constant bonus with polygon fixed effects
reghdfe visit_post_carto $xlist, absorb(a7) vce(robust)

* Append regression results for properties with constant bonus with polygon fixed effects
outreg2 using "/Users/gaelk.bertrand/Desktop/UCB/clean_data/regression_results_q11.xlsx", append excel ctitle("Constant Bonus with Polygon FE")

* Subset data for properties with proportional bonus
use "/Users/gaelk.bertrand/Desktop/UCB/clean_data/merged_data.dta", clear
keep if bonus_prop == 1

* Run regression for properties with proportional bonus with polygon fixed effects
reghdfe visit_post_carto $xlist, absorb(a7) vce(robust)

* Append regression results for properties with proportional bonus with polygon fixed effects
outreg2 using "/Users/gaelk.bertrand/Desktop/UCB/clean_data/regression_results_q11.xlsx", append excel ctitle("Proportional Bonus with Polygon FE")



**** Q12.REGRESSIONS  ****

*Load data again
use "/Users/gaelk.bertrand/Desktop/UCB/clean_data/merged_data.dta", clear
* Define a macro for the variables of interest
global xlist pct50 pct67 pct83 visited visits

* Run regression for all properties
regress taxes_paid $xlist

	** From here you will notice a multicollinearity situation again
	
* Run regression for all properties to attempt to fix multicollinearity
reghdfe taxes_paid $xlist, vce(robust)

* Export regression results for all properties
outreg2 using "/Users/gaelk.bertrand/Desktop/UCB/clean_data/regression_results_q12.xlsx", replace excel ctitle("All Properties")

* Subset data for properties with constant bonus
keep if bonus_constant == 1

* Run regression for properties with constant bonus
reghdfe taxes_paid $xlist, vce(robust)

* Append regression results for properties with constant bonus
outreg2 using "/Users/gaelk.bertrand/Desktop/UCB/clean_data/regression_results_q12.xlsx", append excel ctitle("Constant Bonus")

* Subset data for properties with proportional bonus
use "/Users/gaelk.bertrand/Desktop/UCB/clean_data/merged_data.dta", clear
keep if bonus_prop == 1

* Run regression for properties with proportional bonus
reghdfe taxes_paid $xlist, vce(robust)

* Append regression results for properties with proportional bonus
outreg2 using "/Users/gaelk.bertrand/Desktop/UCB/clean_data/regression_results_q12.xlsx", append excel ctitle("Proportional Bonus")



**** Q13.LAST REGRESSIONS  ****

*Load data again
use "/Users/gaelk.bertrand/Desktop/UCB/clean_data/merged_data.dta", clear
* Define a macro for the variables of interest
global xlist pct50 pct67 pct83 visited visits


* Run regression for all properties
regress ln(taxes_paid) $xlist

** From here you can't proceed because you cannot calculate a ln of a dummy. 


* End of do-file *


* Stop logging and close the log file
log close
