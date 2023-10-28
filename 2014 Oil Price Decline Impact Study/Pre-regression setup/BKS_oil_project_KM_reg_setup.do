// Set more off to prevent pausing while displaying results
set more off

/* Drop missing observations where 'tincode' is missing.
   These are necessary for the first stage of the KM regression. */
drop if missing(tincode)

/* Keep observations that are above 'above_mat_buff'.
   This helps censor loan size in early periods to prevent small loans from vanishing due to materiality.
   If you want a cushion for the buffer, adjust 'above_mat_buff' accordingly. */
keep if above_mat_buff

/* Create 'missing_pastdue' to identify missing 'pastdue' values. */
gen missing_pastdue = missing(pastdue)

/* Convert 'cumulativechargeoffs' to numeric, forcing missing values into numeric. */
destring cumulativechargeoffs, force replace

/* Create a binary variable 'pastdue_dum' to indicate if 'pastdue' is greater than 0. */
gen pastdue_dum = pastdue > 0

/* Create a binary variable 'anychargeoff' to indicate if 'cumulativechargeoffs' is greater than 0. */
gen anychargeoff = cumulativechargeoffs > 0

/* Set 'anychargeoff' to missing if 'cumulativechargeoffs' is missing. */
replace anychargeoff = . if missing(cumulativechargeoffs)

/* Set 'pastdue_dum' to missing if 'missing_pastdue' is 1. */
replace pastdue_dum = . if missing_pastdue == 1

/* Create 'yearacc' to hold the 'year(nonaccrualdate)' values. */
gen yearacc = year(nonaccrualdate)

/* Create 'pastorcharge' to check if there was a past due, any charge off,
   or a non-missing yearacc value (not equal to 9999 and not missing). */
gen pastorcharge = pastdue_dum == 1 | anychargeoff == 1 | (yearacc ~= 9999 & ~missing(yearacc))

/* Drop the intermediate variables. */
drop yearacc pastdue_dum anychargeoff

/* Sort the dataset by 'tincode' and 'date' and create a variable 'pre_stress_date'
   to hold the maximum value of 'pastorcharge' for each 'tincode' and 'date' group. */
bysort tincode date: egen pre_stress_date = max(pastorcharge)

/* Create temporary variables for each year in the range 210-217
   to check if 'pre_stress_date' matches the year (i.e., 1 if it matches, 0 otherwise). */
forval i = 210/217 {
    gen pre_stress`i'_temp = pre_stress_date * (date == `i')
    bysort tincode: egen pre_stress`i' = max(pre_stress`i'_temp)
    drop pre_stress`i'_temp
}

/* Initialize 'pre_stress' to 0. */
gen pre_stress = 0

/* Iterate through the years 214-216 and set 'pre_stress' to 1 if both 'pre_stressX' and 'pre_stressX+1' are 1. */
forval i = 214/216 {
    local k = `i' + 1
    replace pre_stress = 1 if pre_stress`i' == 1 & pre_stress`k' == 1
}

/* Drop temporary variables and 'pre_stress_date'. */
drop pre_stress2* pre_stress_date

/* Create 'pastdue_intervals' to categorize 'pastdue' values into intervals. */
egen pastdue_intervals = cut(pastdue), at(0, 30, 60, 90, 120, 150, 180, 10000)

/* Create binary variables 'pastdue_60' and 'pastdue_90' based on 'pastdue' values. */
gen pastdue_60 = pastdue >= 60
gen pastdue_90 = pastdue >= 90

/* Create 'nonperf_pre' to check if 'km_preoildec_period' and 'pastdue_90' are both 1. */
bysort loanID: egen nonperf_pre = max(km_preoildec_period * pastdue_90)

/* Drop observations with 'nonperf_pre'. */
drop if nonperf_pre

/* Convert 'country' values to uppercase. */
replace country = upper(country)

/* Keep observations where 'country' is "US" to restrict the dataset to the United States. */
keep if country == "US"

/* ... Continue with the rest of the code ... */

/* Create 'foreign_firm' to indicate foreign firms (0 for US firms, 1 for foreign firms). */
gen foreign_firm = 0
replace foreign_firm = 1 if country ~= "US"

/* Create 'firsttb' to identify the first observation for each 'tincode' and 'bhc_name' group. */
bysort tincode bhc_name: gen firsttb = _n == 1

/* Keep observations where 'firsttb' is 1. */
keep if firsttb

/* Drop the 'firsttb' variable. */
drop firsttb

/* Export the dataset to a CSV file, replacing or appending data to the existing file. */
outsheet using "your_file_path.csv", replace

/* Display a message to confirm the export. */
di "Data exported to your_file_path.csv"

/* Set more on to restore the default behavior of displaying results. */
set more on
