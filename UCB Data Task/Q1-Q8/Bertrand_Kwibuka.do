* clear all the current workspace work
clear all
* Logging
log using "/Users/gaelk.bertrand/Desktop/UCB/clean_data/q1-q8.log", replace

/*  
	Filename: Bertrand_data_test(1-8).do
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

* Load or install required packages/dependencies
ssc install estout
ssc install outreg2
ssc install tabout
ssc install ietoolkit
ssc install reghdfe
ssc install ftools


**** Q1. IMPORT DATA ****

use "/Users/gaelk.bertrand/Desktop/UCB/combined_data.dta", clear

* Data exploration to have some insights about data before executing any other task 
// Display dataset information
describe 
// Display variable descriptions and labels
codebook 
// Calculate summary statistics for all variables
summarize, detail 
// Export the summary statistics as a CSV file
outsheet using "/Users/gaelk.bertrand/Desktop/UCB/pre-analysis/summary_statistics.csv", replace

* Data Quality Check
tabulate nb_visit_post_carto 

* Check for outliers in the variables of interest in this data task 'survey_complete' and 'number of visits post carto'
histogram survey_complete, bin(10) title("Histogram of survey_complete ") 
graph export "/Users/gaelk.bertrand/Desktop/UCB//pre-analysis/histogram_survey_complete.png", replace 

histogram nb_visit_post_carto, bin(10) title("Histogram of nb_visit_post_carto ") 
graph export "/Users/gaelk.bertrand/Desktop/UCB//pre-analysis/histogram_nb_visit_post_carto.png", replace 



**** Q2. LIST AND DROP DUPLICATES ****

* List the duplicates based on a unique identifier variable in the dataset: 'compound_code' 
duplicates list compound_code
duplicates report compound_code

* Drop the duplicates if they exist
duplicates drop compound_code, force

* Check if duplicates are all removed
duplicates list compound_code

* Dropping incomplete surveys using variable 'survey_complete':
*drop if survey_complete == "No"

// Here, it is clear that the var 'survey_complete' is not a string
// It can't be easily changed into a string using this:
   * tostring survey_complete, replace
// Therefore,the following steps are necessary:

* First understand the variable 'survey_complete'
describe survey_complete
sum survey_complete

* Define labels for "Yes" and "No"
label define survey_complete_label 0 "No" 1 "Yes"

* Apply labels to the numeric values of survey_complete
label values survey_complete survey_complete_label

* Tabulate survey_complete to verify labels
tabulate survey_complete
describe survey_complete

* Now drop incomplete surveys according to 'survey_complete'
drop if survey_complete == 0

* Save the new dataset
save "/Users/gaelk.bertrand/Desktop/UCB/clean_data/combined_data.dta", replace



**** Q3. MERGING WITH nearest_property DATASET ****

// Here, please take note that the dataset 'nearest_property' is in csv format

* Read the CSV file
insheet using "/Users/gaelk.bertrand/Desktop/UCB/nearest_property.csv", clear

* Save the dataset in Stata format ".dta"
save "/Users/gaelk.bertrand/Desktop/UCB/clean_data/nearest_property.dta", replace

// Before merging, determine the common variables first or unique identifier variable

* Load master data "combined_data.dta" again
use "/Users/gaelk.bertrand/Desktop/UCB/clean_data/combined_data.dta", clear

* Get the list of variable names in the master dataset
ds
local master_vars = r(varlist)

* Load the using dataset or secondary data
use "/Users/gaelk.bertrand/Desktop/UCB/clean_data/nearest_property.dta", clear

* Get the list of variable names in the using dataset
ds
local using_vars = r(varlist)

* Compare variable names in both datasets
local common_vars : list master_vars & using_vars
display "`common_vars'"

* Check on the type of the unique identifier (compound_code) in both datasets before merging
** For the Main dataset
use "/Users/gaelk.bertrand/Desktop/UCB/clean_data/combined_data.dta", clear
describe compound_code
* Sort the dataset based on the unique identifier
gsort compound_code
save "/Users/gaelk.bertrand/Desktop/UCB/clean_data/combined_data.dta", replace

** For the Using dataset
use "/Users/gaelk.bertrand/Desktop/UCB/clean_data/nearest_property.dta", clear
describe compound_code
* Sort the dataset based on the unique identifier
gsort compound_code
save "/Users/gaelk.bertrand/Desktop/UCB/clean_data/nearest_property.dta", replace


** After finding that the type of the unique identifier differs, now I can address it:

* Recode 'compound_code' into a long format in the 'combined_data' like in 'nearest_property'
use "/Users/gaelk.bertrand/Desktop/UCB/clean_data/combined_data.dta", clear
	* Convert compound_code to string first
tostring compound_code, gen(compound_code_str)
	* Convert compound_code_str back to numeric (long)
destring compound_code_str, gen(compound_code_long)
	* Drop the old compound_code variable
drop compound_code
	* Rename compound_code_long to compound_code
rename compound_code_long compound_code
	* Save changes
save "/Users/gaelk.bertrand/Desktop/UCB/clean_data/combined_data.dta", replace

* Merge accordingly
	* Load the main dataset 
use "/Users/gaelk.bertrand/Desktop/UCB/clean_data/combined_data.dta", clear

	* Create a temp file 
tempfile temp1
save `temp1'
use "/Users/gaelk.bertrand/Desktop/UCB/clean_data/nearest_property.dta", clear

	* Merge the datasets based on compound_code
merge 1:1 compound_code using `temp1', keep(master match)

	* Save the merged dataset
save "/Users/gaelk.bertrand/Desktop/UCB/clean_data/merged_data.dta", replace



**** Q4.Imputing missing values of number of visits post carto using polygon average ****

* Load the merged data
use "/Users/gaelk.bertrand/Desktop/UCB/clean_data/merged_data.dta", clear

* Identify the right variable corresponding to 'number of visits post carto'
ds *visit* *carto*

* Display labels of variables containing keywords related to visits and carto
describe visits, detail
describe visit_post_carto, detail
describe nb_visit_post_carto, detail
describe today_carto, detail


* Calculate average number of visits post carto for each polygon

   * Calculate the polygon average for nb_visit_post_carto
egen polygon_avg = mean(nb_visit_post_carto), by(a7)

   * Impute missing values of nb_visit_post_carto using the polygon average
replace nb_visit_post_carto = polygon_avg if mi(nb_visit_post_carto)
 
   * Drop the polygon_avg variable as it's no longer needed
drop polygon_avg

**If not all missing values are not imputed, you can proceed with the following:

  * Calculate the global average for nb_visit_post_carto
summarize nb_visit_post_carto, meanonly
local global_avg = r(mean)

  * Impute remaining missing values of nb_visit_post_carto using the global average
replace nb_visit_post_carto = `global_avg' if mi(nb_visit_post_carto)

  * Save the merged dataset
save "/Users/gaelk.bertrand/Desktop/UCB/clean_data/merged_data.dta", replace



**** Q5.Generating the log version of the variable "rate" ***

* Find which type is the variable 'rate'
describe rate 

* Convert the string variable "rate" to numeric
destring rate, replace

* Generate the log version of the numeric variable
gen log_rate = log(rate)

  * Save the merged dataset
save "/Users/gaelk.bertrand/Desktop/UCB/clean_data/merged_data.dta", replace



**** Q6. Dummy variables for percentage of tax rate to be paid ****

* Generate dummy variables for reduction_pct
tabulate reduction_pct, generate(pct)

* Rename the dummy variables
rename pct1 pct50
rename pct2 pct67
rename pct3 pct83
rename pct4 pct100

* Label the dummy variables
label variable pct50 "50% Reduction"
label variable pct67 "33% Reduction"
label variable pct83 "17% Reduction"
label variable pct100 "0% Reduction"

* Save the new dataset
save "/Users/gaelk.bertrand/Desktop/UCB/clean_data/merged_draft.dta", replace


**** Q7. Plots for the subset of those that paid taxes, by tax reduction percentages *****

   * Subset the data to those that paid taxes
keep if taxes_paid == 1

   * Generate the minimum day of tax payment for each tax reduction percentage
egen min_day_pct50 = min(taxes_paid_0d/taxes_paid_30d) if pct50 == 1
egen min_day_pct67 = min(taxes_paid_0d/taxes_paid_30d) if pct67 == 1
egen min_day_pct83 = min(taxes_paid_0d/taxes_paid_30d) if pct83 == 1
egen min_day_pct100 = min(taxes_paid_0d/taxes_paid_30d) if pct100 == 1

   * Plot the minimum day of tax payment for each tax reduction percentage
twoway (histogram min_day_pct50, frequency), title("50% Reduction") ytitle("Frequency") xtitle("Day of Tax Payment") name(gr1, replace)
twoway (histogram min_day_pct67, frequency), title("33% Reduction") ytitle("Frequency") xtitle("Day of Tax Payment") name(gr2, replace)
twoway (histogram min_day_pct83, frequency), title("17% Reduction") ytitle("Frequency") xtitle("Day of Tax Payment") name(gr3, replace)
twoway (histogram min_day_pct100, frequency), title("0% Reduction") ytitle("Frequency") xtitle("Day of Tax Payment") name(gr4, replace)

   * Combine the four graphs into one graph
graph combine gr1 gr2 gr3 gr4, title("Minimum Day of Tax Payment by Tax Reduction Percentage")

   * Clean up
drop min_day_pct50 min_day_pct67 min_day_pct83 min_day_pct100

   * Save the new dataset
save "/Users/gaelk.bertrand/Desktop/UCB/clean_data/merged_data.dta", replace


**** Q8. Average taxes paid amount ****

  * Calculate the total number of compounds and the number of compounds that paid taxes for each polygon
egen total_compounds = total(1), by(a7)
egen total_paid_taxes = total(taxes_paid), by(a7)

  * Calculate the percentage of compounds that paid taxes for each polygon
gen pct_paid_taxes = total_paid_taxes / total_compounds

  * Subset the data to polygons where over 5% of the compounds paid taxes
keep if pct_paid_taxes > 0.05

  * Calculate the average taxes paid amount
summarize taxes_paid_amt, meanonly

  * Display the average taxes paid amount rounded to three decimal places
di "The average taxes paid amount for all observations in polygons where over 5% of the compounds paid taxes is " round(r(mean), 0.001)

  * Clean up
drop total_compounds total_paid_taxes pct_paid_taxes
* Save the new dataset
save "/Users/gaelk.bertrand/Desktop/UCB/clean_data/merged_data.dta", replace

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



* Stop logging and close the log file
log close
