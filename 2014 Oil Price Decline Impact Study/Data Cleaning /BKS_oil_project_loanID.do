/*
   BKS_oil_project_loanID generates a loan-specific identifier that remains constant over time.
   These identifiers are created based on the bank-provided internalcreditfacilityid and originalinternalcreditfacilityid.
   The construction method addresses situations where IDs are shared across multiple banks and,
   more complexly, when banks change IDs for a specific loan over time, necessitating examination of originalinternalcreditfacilityid.
*/

set more off

* In the first period, overwrite the originalinternalcreditfacilityid with internalcreditfacilityid
* as they should be identical and in the (tiny) number of cases that they are not the original
* is irrelevant and we are simply imposing the Y14 requested format
replace originalinternalcreditfacilityid = internalcreditfacilityid if date == 206 //20111Q3 = 206 is the first filing period and there shouldn't have been a "previous submission"

* Look for code clashes within banks (drop if having the same internal credit ID in the same filing as it should be unique within the bank)
bysort bhc internalcreditfacilityid date: gen num_ID_in_filing = _N if !missing(internalcreditfacilityid)
by bhc internalcreditfacilityid date: gen dup_ID_in_filing = num_ID_in_filing > 1 & !missing(num_ID_in_filing) // Should be unique within the bank-date
bysort bhc internalcreditfacilityid: egen dup_ID_in_a_filing = max(dup_ID_in_filing)
drop if dup_ID_in_a_filing == 1 // Drop all observations with that id if any duplications

* Look for code clashes across banks
bysort internalcreditfacilityid bhc: gen f_loanID_bhc = _n == 1 & !missing(internalcreditfacilityid)
bysort internalcreditfacilityid: egen n_same_loanID = total(f_loanID_bhc), missing
tab n_same_loanID // >1 -> banks inadvertently use the same code

* Retain only the credit IDs and banks that clash - then assign a unique code to them
preserve
bysort internalcreditfacilityid bhc: keep if f_loanID_bhc & n_same_loanID > 1
gen index_n = _n
tostring index_n, replace
replace index_n = "GaelK.Bertrand/Replication exercise STATA"+index_n
keep internalcreditfacilityid bhc index_n
sort internalcreditfacilityid bhc
capture save "GaelK.Bertrand/Replication exercise STATA/Output/Temporary/duplicate_ids.dta", replace
restore

* Merge back into the dataset and override clashing codes with the newly created unique codes
capture drop _merge
sort internalcreditfacilityid bhc
merge internalcreditfacilityid bhc using "GaelK.Bertrand/Replication exercise STATA/Output/Temporary/duplicate_ids.dta"
gen succ_loan_merge = _merge == 3
gen new_loanID = internalcreditfacilityid
replace new_loanID = index_n if succ_loan_merge
gen orig_internalcreditfacilityid = internalcreditfacilityid // Save before overwriting
replace internalcreditfacilityid = new_loanID

* Tab and browse to see if we now have unique codes
drop f_loanID_bhc n_same_loanID
bysort internalcreditfacilityid bhc: gen f_loanID_bhc = _n == 1 if !missing(internalcreditfacilityid)
bysort internalcreditfacilityid: egen n_same_loanID = total(f_loanID_bhc), missing
tab n_same_loanID // Should now be all 1. At this point we have uniquely identified loans within the period but the loans' IDs may change

* Capture save
capture save "GaelK.Bertrand/Replication exercise STATA/Output/Temporary/temp_BKS_oil_pre_backfill.dta", replace

preserve
clear
use "GaelK.Bertrand/Replication exercise STATA/Output/Temporary/duplicate_ids.dta"
rename internalcreditfacilityid originalinternalcreditfacilityid
sort originalinternalcreditfacilityid bhc
capture save "GaelK.Bertrand/Replication exercise STATA/Output/Temporary/duplicateorig_ids.dta", replace
restore

* Merge back into the dataset and override clashing codes with the newly created unique codes
capture drop _merge
sort originalinternalcreditfacilityid bhc
merge originalinternalcreditfacilityid bhc using "GaelK.Bertrand/Replication exercise STATA/Output/Temporary/duplicateorig_ids.dta"
gen succ_loan_merge_orig = _merge == 3
gen new_loanID_orig = originalinternalcreditfacilityid
replace new_loanID_orig = index_n if succ_loan_merge_orig
gen orig_originternalcrfacilityid = originalinternalcreditfacilityid
replace originalinternalcreditfacilityid = new_loanID_orig

gen loanID_raw = internalcreditfacilityid
replace loanID_raw = originalinternalcreditfacilityid if !missing(originalinternalcreditfacilityid) // loanID_raw should be the same over time for a given loan

* Create the ultimate loanID that will be used going forward
egen loanID = group(loanID_raw)
bysort loanID: gen n_periods_in_y14 = _N
tab n_periods_in_y14 // Should be no loans with more than 17 periods (in fact we find a tiny number that do)

* JK edit: data update, drop if n_periods_in_y14 > 21
drop if n_periods_in_y14 > 21

drop loanID_raw n_periods_in_y14 succ_loan_merge_orig index_n

/* Take a random sample */
preserve
bysort loanID: keep if _n == 1
gen r_unif = runiform()
drop if r_unif >= 0.10
keep loanID
sort loanID
capture save "GaelK.Bertrand/Replication exercise STATA/Output/Temporary/loanIDsample.dta", replace
restore

preserve
capture drop _merge
sort loanID
merge loanID using "GaelK.Bertrand/Replication exercise STATA/Output/Temporary/loanIDsample.dta"
keep if _merge == 3
capture save "GaelK.Bertrand/Replication exercise STATA/Output/Temporary/temp_BKS_oil_post_loanID_sample10.dta", replace
restore
compress
