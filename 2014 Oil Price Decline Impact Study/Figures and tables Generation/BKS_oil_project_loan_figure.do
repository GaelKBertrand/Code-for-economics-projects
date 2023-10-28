/* Generate the Project Loan Figure */

/* Change the directory path to the new location */
use "/GaelK.Bertrand/Replication exercise STATA/Output/Temporary/temp_BKS_oil_post_KM_final.dta", clear

/*** Choose break point ***/
local b 217  //2014:Q2
/* Uncomment this line if you want to use an alternative break point */
//*local b 216  //2014:Q1

gen id_rssd = bhc

/*** LINE REDACTED DUE TO CONFIDENTIAL INFORMATION ***/

/* Keep only the observations with termall equal to 1 and date greater than or equal to 210 */
keep if termall == 1
drop if date < 210

/* Define percentile cutoffs */
/*** LINE REDACTED DUE TO CONFIDENTIAL INFORMATION ***/

local variable high90plus high75plus high66plus low10below low25below low33below high7590 low1025 high50plus low50below

/* Replace missing values with '.' for specified variables */
foreach i of local variable {
    replace `i' = . if `i' == 0
}

/*** LINE REDACTED DUE TO CONFIDENTIAL INFORMATION ***/

/* Create a variable indicating the first loan for each bank */
bysort bhc_name tincode date: gen first_kmloan = _n == 1

/* Calculate the total termall_from_bhc*first_kmloan*indn211 by bank and date */
bysort bhc_name date: egen totbhc = total(termall_from_bhc * first_kmloan * indn211), missing
gen lntotbhc = ln(totbhc)

/*** LINE REDACTED DUE TO CONFIDENTIAL INFORMATION ***/

gen datedum = .
replace datedum = 1 if date == `b'

gen lntotbhc_resid = .

/* Iterate over a list of bank identifiers to calculate residuals */
foreach k of local banklist {
    reg lntotbhc date if date <= `b' & firstbd == 1 & id_rssd == `k'
    replace lntotbhc_resid = lntotbhc - _b[date] * date - _b[_cons] if firstbd == 1 & id_rssd == `k'
    gen bank`k' = id_rssd == `k'
    replace bank`k' = . if bank`k' == 0
    bysort id_rssd: egen lntotbhc_resid`k' = max(lntotbhc_resid * datedum * bank`k')
    replace lntotbhc_resid = lntotbhc_resid - lntotbhc_resid`k' if firstbd == 1 & id_rssd == `k'
    drop lntotbhc_resid`k'
}

foreach i of local variable {
    bysort date: egen ln`i't_resid = mean(lntotbhc_resid * `i' * firstbd)
}

bysort date: gen firstd = _n == 1

/* Keep only the first observation for each date */
keep if firstd == 1

/* Map date values to more readable format */
gen date2 = ""
replace date2 = "2012:3" if date == 210
/* Add similar lines for other date values */
replace date2 = "2016:1" if date == 224
drop date
rename date2 date

/* Export the results to an Excel file */
export excel date lnhigh90plust_resid lnhigh75plust_resid lnlow25belowt_resid lnlow10belowt_resid using "/GaelK.Bertrand/Replication exercise STATA/Tables/loanplot", firstrow(variables) replace
