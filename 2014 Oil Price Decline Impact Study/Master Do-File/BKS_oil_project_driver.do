/**************************************************************
* BKS_oil_project_driver.do: Master driver file for data cleansing and results generation.
* Directories have been modified for confidentiality.
**************************************************************/

clear
cls
set more off

// Change the working directory to the secure directory where the data is located
cd "/GaelK.Bertrand/Replication exercise STATA/Final Scripts"

// Use the updated Y14 data set through 2016.q3
use "/GaelK.Bertrand/Replication exercise STATA/Data/V_CIL_Q_nov16.dta", clear

/**************************************************************
* Basic administrative cleaning
**************************************************************/

// Execute data cleaning script
do "/GaelK.Bertrand/Replication exercise STATA/Final Scripts/BKS_oil_project_cleaning.do"

// Save the cleaned data temporarily
save "/GaelK.Bertrand/Replication exercise STATA/Output/Temporary/temp_BKS_oil_post_clean.dta", replace

/**************************************************************
* Cleaning / filling TINs
**************************************************************/

// Execute TIN cleaning script
do "/GaelK.Bertrand/Replication exercise STATA/Final Scripts/BKS_oil_project_TIN.do"

// Save the TIN-cleaned data temporarily
save "/GaelK.Bertrand/Replication exercise STATA/Output/Temporary/temp_BKS_oil_post_tin.dta", replace

/**************************************************************
* Constructing loanID
**************************************************************/

// Execute loanID construction script
do "/GaelK.Bertrand/Replication exercise STATA/Final Scripts/BKS_oil_project_loanID.do"

// Save the loanID-constructed data temporarily
save "/GaelK.Bertrand/Replication exercise STATA/Output/Temporary/temp_BKS_oil_post_loanID.dta", replace

/**************************************************************
* NAICS etc.
**************************************************************/

// Execute NAICS cleaning script
do "/GaelK.Bertrand/Replication exercise STATA/Final Scripts/BKS_oil_project_industries.do"

// Save the NAICS-cleaned data temporarily
save "/GaelK.Bertrand/Replication exercise STATA/Output/Temporary/temp_BKS_oil_post_industries.dta", replace

/**************************************************************
* Initial prep for KM analysis
**************************************************************/

// Execute prep script for KM analysis
do "/GaelK.Bertrand/Replication exercise STATA/Final Scripts/BKS_oil_project_KM_prep.do"

// Save the KM prep data temporarily
save "/GaelK.Bertrand/Replication exercise STATA/Output/Temporary/temp_BKS_oil_post_KM_prep.dta", replace

/**************************************************************
* Regression setup for KM analysis
**************************************************************/

// Execute regression setup script for KM analysis
do "/GaelK.Bertrand/Replication exercise STATA/Final Scripts/BKS_oil_project_KM_reg_setup.do"

// Save the regression setup data temporarily
save "/GaelK.Bertrand/Replication exercise STATA/Output/Temporary/temp_BKS_oil_post_KM_reg_setup.dta", replace

/**************************************************************
* Compustat merge
**************************************************************/

// Execute script for merging with Compustat data
do "/GaelK.Bertrand/Replication exercise STATA/Final Scripts/BKS_oil_project_KM_compustat_merge.do"

// Save the merged data temporarily
save "/GaelK.Bertrand/Replication exercise STATA/Output/Temporary/temp_BKS_oil_post_KM_final.dta", replace

/**************************************************************
* Regressions
**************************************************************/

// Execute regressions script for KM analysis
do "/GaelK.Bertrand/Replication exercise STATA/Final Scripts/BKS_oil_project_KM_regressions_2wayclust.do"

// Save the regression results temporarily
save "/GaelK.Bertrand/Replication exercise STATA/Output/Temporary/temp_BKS_oil_post_KM_regressions.dta", replace

/**************************************************************
* Table
**************************************************************/

// Execute script for creating tables
do "/GaelK.Bertrand/Replication exercise STATA/Final Scripts/BKS_oil_project_tables.do"

/**************************************************************
* Mortgage Analysis
**************************************************************/

clear all

/**************************************************************
* Clean Data and Make Dependent Variables
**************************************************************/

// Execute script for cleaning data and creating dependent variables
do "/GaelK.Bertrand/Replication exercise STATA/Final Scripts/BKS_oil_project_mortgage_quant.do"

// Save the cleaned mortgage data temporarily
save "/GaelK.Bertrand/Replication exercise STATA/Output/Temporary/mortgage_quant", replace

/**************************************************************
* Make Price Variables
**************************************************************/

// Load the cleaned data and execute script for creating price variables
use "/GaelK.Bertrand/Replication exercise STATA/Output/Temporary/mortgage_quant", clear
do "/GaelK.Bertrand/Replication exercise STATA/Final Scripts/BKS_oil_project_mortgage_price.do"

// Save the data with price variables temporarily
save "/GaelK.Bertrand/Replication exercise STATA/Output/Temporary/mortgage_quantprice", replace

/**************************************************************
* Create County Level Dataset, Merge in County Controls
**************************************************************/

// Load the data with price variables and execute script for creating county-level dataset
use "/GaelK.Bertrand/Replication exercise STATA/Output/Temporary/mortgage_quantprice", clear
do "/GaelK.Bertrand/Replication exercise STATA/Final Scripts/BKS_oil_project_mortgage_prereg.do"

// Save the county-level data temporarily
save "/GaelK.Bertrand/Replication exercise STATA/Output/Temporary/mortgage_countylev", replace

/**************************************************************
* Regressions
**************************************************************/

// Load the county-level data and execute script for running regressions
use "/GaelK.Bertrand/Replication exercise STATA/Output/Temporary/mortgage_countylev", clear
do "/GaelK.Bertrand/Replication exercise STATA/Final Scripts/BKS_oil_project_mortgage_regressions.do"

/**************************************************************
* Tables
**************************************************************/

// Execute script for creating tables related to mortgage analysis
do "/GaelK.Bertrand/Replication exercise STATA/Final Scripts/BKS_oil_project_mortgage_tables.do"
