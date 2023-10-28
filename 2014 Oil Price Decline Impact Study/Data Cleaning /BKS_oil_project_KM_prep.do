/* BKS_oil_project_KM_prep.do performs administrative setup for KM analysis, laying the groundwork for the creation of regression variables. */

// Set the display option to show more results
set more off

*-------------------------------------------------------------------------------
* Basic cleaning

// Drop observations before 2012Q3
drop if date < 210

// Drop rows with missing bank (bhc) information
drop if missing(bhc)

*-------------------------------------------------------------------------------
* Periods
* NOTE: WTI starts decline in July 2014 (2014:Q3), share decline starts in Q4 and the last period of declining price between Dec 2014 and Jan 2015

// Generate period variables for KM analysis
gen km_preoildec_period = date <= 217 // 217 is 2014Q2
gen km_postoildec_period = date >= 220 & date <= 222 // 2015Q1 through 2016Q3
gen km_oildec_period = inlist(date, 218, 219) // 2014Q3 and Q4

gen km_periods = km_preoildec_period*(-1) + km_oildec_period*0 + km_postoildec_period*(1)
replace km_periods = . if date >= 223

gen km_preoildec_period_dot = km_preoildec_period
replace km_preoildec_period_dot = . if !km_preoildec_period
gen km_postoildec_period_dot = km_postoildec_period
replace km_postoildec_period_dot = . if !km_postoildec_period

*-------------------------------------------------------------------------------
* Fix drilling variable

// Relabel specific industry codes to  NAICS code 211
gen ind3_new = 0
replace ind3_new = 1 if substr(industrycode, 1, 3) == "211" | inlist(industrycode, "213111", "213112")
bysort tincode: egen frac_211 = mean(ind3_new)
by tincode: egen any_211 = max(ind3_new)

// Create an energy flag based on obligor names
gen energy_flag = regexm(obligorname, "GAS|DRILL|ENERGY|OIL|PROPANE|PIPE|POWER|RESOURCE|INERGY|MATERIAL|PETROL|SANJEL|TECHNOLOGIES|OPERATING")
bysort tincode: egen any_energy = max(energy_flag)
by tincode: egen frac_energy = mean(energy_flag)

// Update ind3 based on energy and industry code
gen orig_ind3 = ind3
replace ind3 = "211" if frac_211 > 0.5 & ~missing(tincode) & ~missing(frac_211)
replace ind3 = "211" if frac_211 > 0.1 & any_energy == 1 & ~missing(tincode) & ~missing(frac_211) & ~missing(any_energy)
replace ind3 = "211" if frac_energy > 0.1 & any_211 == 1 & ~missing(tincode) & ~missing(frac_energy) & ~missing(any_211)

// Relabel the missing tins
replace ind3 = "211" if ind3_new == 1 & missing(tincode)
replace ind3 = "211" if energy_flag == 1 & missing(tincode)

* Merge in Y-9 control variables
preserve
do GaelK.Bertrand/Replication exercise STATA/BKS_clean_y9_data.do
restore
capture drop _merge
sort bhc date
merge m:1 bhc date using "/classified/l1jrk0b_l1rmb01/Data/Compustat/y9_data_for_y14.dta"
capture drop _merge
drop if date < 210

* Industry shares
bysort bhc ind3: egen ind3_1213_committed = total(committedexposure*(year_y14 == 2012 | year_y14 == 2013)), missing
bysort bhc: egen tot_1213_committed = total(committedexposure*(year_y14 == 2012 | year_y14 == 2013)), missing
gen share_1213_committed = ind3_1213_committed/tot_1213_committed

bysort bhc: egen share211_1213_committed = max(share_1213_committed*(ind3 == "211"))

bysort bhc ind3: egen ind3_pre_committed = total(committedexposure*(km_periods == -1)), missing
bysort bhc: egen tot_pre_committed = total(committedexposure*(km_periods == -1)), missing
gen share_pre_committed = ind3_pre_committed/tot_pre_committed

by bhc: egen share211_pre_committed = max(share_pre_committed*(ind3 == "211"))
egen bank_date_tag = tag(bhc date)

bysort bhc: egen tot_1213_totloans = total(bank_date_tag*total_loans*(year_y14 == 2012 | year_y14 == 2013)), missing
gen share_1213_totloans = ind3_1213_committed/(tot_1213_totloans*1000)
bysort bhc: egen share211_1213_totloans = max(share_1213_totloans*(ind3 == "211"))

bysort bhc: egen tot_1213_totassets = total(bank_date_tag*total_assets*(year_y14 == 2012 | year_y14 == 2013)), missing
gen share_1213_totassets = ind3_1213_committed/(tot_1213_totassets*1000)
bysort bhc: egen share211_1213_totassets = max(share_1213_totassets*(ind3 == "211"))

bysort bhc: egen tot_1213_equity = total(bank_date_tag*equity_cap*(year_y14 == 2012 | year_y14 == 2013)), missing
gen share_1213_equity = ind3_1213_committed/(tot_1213_equity*1000)
bysort bhc: egen share211_1213_equity = max(share_1213_equity*(ind3 == "211"))

drop bank_date_tag share_1213_totassets tot_1213_totloans tot_1213_totloans share_1213_totloans tot_1213_equity share_1213_equity frac_211 any_211 ind3_new frac_energy energy_flag any_energy tot_1213_committed share_1213_committed ind3_pre_committed tot_pre_committed share_pre_committed

*-------------------------------------------------------------------------------
* Aggregate facility types

// Convert facilitytype to a string
tostring facilitytype, replace

bysort loanID: egen util = total(utilizedexposure), missing
by loanID: egen com = total(committedexposure), missing

drop if com == 0

gen share = util/com

gen otherlease = 0
replace otherlease = regexm(otherfacilitytype, "LEASE|LEASING") | regexm(otherfacilitypurpose, "LEASE|LEASING")

replace otherlease = 1 if (regexm(otherfacilitypurpose, "LEASE|LEASING"))

gen otherloan = 0
replace otherloan = regexm(otherfacilitytype, "LOAN|MORTGAGE|MEZZANINE|BOND|BOND") | regexm(otherfacilitypurpose, "LOAN|MORTGAGE|MEZZANINE|BOND|BOND")
replace otherloan = 1 if (regexm(otherfacilitypurpose, "LOAN|MORTGAGE|MEZZANINE|BOND|BOND"))

gen otherline = 0
replace otherline = regexm(otherfacilitytype, "CARD|REVOLV|LINE|LETTER") | regexm(otherfacilitypurpose, "CARD|REVOLV|LINE|LETTER")
replace otherline = 1 if (regexm(otherfacilitypurpose, "CARD|REVOLV|LINE|LETTER"))
replace otherline = 0 if regexm(otherfacilitytype, "PIPELINE")

forval i = 0/17 {
    bysort loanID: egen fac`i' = max(facilitytype == "`i'")
}
bysort loanID: egen facotherlease = max(otherlease)
bysort loanID: egen facotherline = max(otherline)
bysort loanID: egen facotherloan = max(otherloan)

gen termall = 0
replace termall = 1 if (fac7 == 1 | fac8 == 1 | fac9 == 1 | fac10 == 1 | fac11 == 1 | fac12 == 1 | fac13 == 1)

gen lineofcredit = 0
replace lineofcredit = 1 if (fac1 == 1 | fac2 == 1 | fac3 == 1 | fac4 == 1 | fac5 == 1 | fac6 == 1 | fac15 == 1 | facotherline == 1)

// Added on 8/18/16: Destring interest rate
destring interestrate, replace force
replace interestrate = interestrate / 100 if interestrate > 1
replace interestrate = . if interestrate < 0

gen flag = 0
replace flag = 1 if (interestrate == 0 | missing(interestrate)) & utilizedexposure < committedexposure & ~missing(committedexposure) & ~missing(utilizedexposure) & termall == 1
bysort loanID: egen flag_line = max(flag)
drop flag

gen flag = 0
replace flag = 1 if interestrate > 0 & ~missing(interestrate) & share == 1 & ~missing(committedexposure) & ~missing(utilizedexposure) & termall == 0
bysort loanID: egen flag_term = max(flag)
drop flag

replace termall = 0 if share < 0.9 & termall == 1 & lineofcredit == 1
replace termall = 0 if flag_line == 1
replace termall = 1 if flag_term == 1
replace lineofcredit = 0 if share >= 0.9 & termall == 1 & lineofcredit == 1
replace lineofcredit = 1 if flag_line == 1
replace lineofcredit = 0 if flag_term == 1
drop flag_line flag_term

gen other = termall == 0 & lineofcredit == 0
replace other = 0 if other ~= 1

// Create loan type exposures
local loan_type_list_1 termall lineofcredit
foreach i in `loan_type_list_1' {
    replace `i' = . if `i' == 0
    gen `i'exposure = `i' * committedexposure
    replace `i' = 0 if `i' == .
}

// Clean up unnecessary variables
drop fac0 fac1 fac2 fac3 fac4 fac5 fac6 fac7 fac8 fac9 fac10 fac11 fac12 fac13 fac14 fac15 fac16 fac17 facotherline facotherloan facotherlease util com share
compress
