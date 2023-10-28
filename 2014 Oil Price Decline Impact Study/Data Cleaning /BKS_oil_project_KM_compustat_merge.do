/******************************************************
* DO-FILE for generating Compustat balance sheet indicators and merging them into the Y14 database
* First version: 7/15/2016, J. Krainer
******************************************************/

cd "GaelK.Bertrand/Replication exercise STATA/Data/Compustat"

use "GaelK.Bertrand/Replication exercise STATA/Data/Compustat/cap_issQ_w_stn_name.dta", clear

/*
   Drop observations with missing values in specific variables
   - cheq, actq, atq, lctq, dlttq, ltq, teqq, cshlq, nlq, capxq, sstkq, txbcofq, prstkq, dvq, dltlsq, dltrq, dlcchq, flaoq, flncfq
   This helps clean the data by removing incomplete records.
*/
drop if missing(cheq) & missing(actq) & missing(atq) & missing(lctq) & missing(dlttq) & missing(ltq) & missing(teqq) ///
    /*& missing(cshoq)*/ & missing(cshlq) & missing(nlq) & missing(capxq) & missing(sstkq) & missing(txbcofq) & missing(prstkq) ///
    & missing(dvq) & missing(dltlsq) & missing(dltrq) & missing(dlcchq) & missing(flaoq) & missing(flncfq)

/******************************************************
* Store quarterly averages pre and post oil shock for second stage regressions
******************************************************/
gen pre_oil_shock = date < 218
replace pre_oil_shock = . if pre_oil_shock == 0
gen post_oil_shock = date > 219 & date < 223
replace post_oil_shock = . if post_oil_shock == 0

sort gvkey date

/* Calculate quarterly averages for specific balance sheet variables */
by gvkey: egen ASSETS_bef = mean(atq * pre_oil_shock)
by gvkey: egen ASSETS_aft = mean(atq * post_oil_shock)
by gvkey: egen LIAB_bef = mean(ltq * pre_oil_shock)
by gvkey: egen LIAB_aft = mean(ltq * post_oil_shock)
by gvkey: egen EQUITY_bef = mean(teqq * pre_oil_shock)
by gvkey: egen EQUITY_aft = mean(teqq * post_oil_shock)

/* Calculate the changes in balance sheet variables */
gen d_ASSETS = ln(ASSETS_aft) - ln(ASSETS_bef)
gen d_LIAB = ln(LIAB_aft) - ln(LIAB_bef)
gen d_EQUITY = ln(EQUITY_aft) - ln(EQUITY_bef)

gen quarter = quarter(dofq(date))

/* Recode fiscalyr to denote the first quarter of the fiscal year */
gen fiscalqtr = .
replace fiscalqtr = 2 if fiscalyr <= 3 & fiscalyr > 0
replace fiscalqtr = 3 if fiscalyr <= 6 & fiscalyr > 3
replace fiscalqtr = 4 if fiscalyr <= 9 & fiscalyr > 6
replace fiscalqtr = 1 if fiscalyr <= 12 & fiscalyr > 9

sort gvkey date

/******************************************************
* Calculate changes in specific variables
******************************************************/
gen diff_div = dvq
gen diff_capx = capxq
gen diff_ltdebt_issue = dltlsq
gen diff_stock_issue = sstkq

local i = 1
while `i' <= 4 {
    by gvkey: replace diff_div = dvq - dvq[_n-1] if quarter != `i' & fiscalqtr == `i'
    by gvkey: replace diff_capx = capxq - capxq[_n-1] if quarter != `i' & fiscalqtr == `i'
    by gvkey: replace diff_ltdebt_issue = dltlsq - dltlsq[_n-1] if quarter != `i' & fiscalqtr == `i'
    by gvkey: replace diff_stock_issue = sstkq - sstkq[_n-1] if quarter != `i' & fiscalqtr == `i'
    local i = `i' + 1
}

/* Calculate changes in specific variables */
by gvkey: egen DIV_bef = mean(diff_div * pre_oil_shock)
by gvkey: egen DIV_aft = mean(diff_div * post_oil_shock)
gen d_DIV = ln(DIV_aft) - ln(DIV_bef)

by gvkey: egen CAPX_bef = mean(diff_capx * pre_oil_shock)
by gvkey: egen CAPX_aft = mean(diff_capx * post_oil_shock)
gen d_CAPX = ln(CAPX_aft) - ln(CAPX_bef)

by gvkey: egen LTD_bef = mean(diff_ltdebt_issue * pre_oil_shock)
by gvkey: egen LTD_aft = mean(diff_ltdebt_issue * post_oil_shock)
gen d_LTD = ln(LTD_aft) - ln(LTD_bef)

by gvkey: egen STOCK_bef = mean(diff_stock_issue * pre_oil_shock)
by gvkey: egen STOCK_aft = mean(diff_stock_issue * post_oil_shock)
gen d_STOCK = ln(STOCK_aft) - ln(STOCK_bef)

/* Calculate the leverage ratio */
gen levratio = ltq / atq
by gvkey: egen LEVRATIO_bef = mean(levratio * pre_oil_shock)
by gvkey: egen LEVRATIO_aft = mean(levratio * post_oil_shock)
gen d_LEVRATIO = LEVRATIO_aft - LEVRATIO_bef

/******************************************************
* Merge in Employees from the annual data set
******************************************************/
sort gvkey date
merge 1:1 gvkey date using compustat_employees
drop _merge

sort gvkey date

/* Calculate changes in the number of employees */
by gvkey: egen EMP_bef = mean(employeesc * pre_oil_shock)
by gvkey: egen EMP_aft = mean(employeesc * post_oil_shock)
gen d_EMP = ln(EMP_aft) - ln(EMP_bef)

/* Split the ein variable to create the tin variable */
split ein, p("-")
gen tin = ein1 + ein2
drop ein1 ein2

/* Keep only the necessary variables for merging */
keep tin stn_name tkr cusip d_LIAB d_ASSETS d_EQUITY d_CAPX d_STOCK d_LEVRATIO d_EMP d_DIV
tempfile comp
save `comp'

/******************************************************
* Merging Data
******************************************************/
local varlist d_LIAB d_ASSETS d_EQUITY d_CAPX d_STOCK d_LEVRATIO d_EMP d_DIV

/* Create separate merge files for tin, stn_name, tkr, and cusip */
bysort tin: keep if _n == 1
drop if missing(tin)
drop tkr cusip stn_name
foreach var in `varlist' {
    rename `var' `var'_tin
}
tempfile tin_comp
save `tin_comp'

use `comp', clear
bysort stn_name: keep if _n == 1
drop if missing(stn_name)
drop tkr cusip tin
foreach var in `varlist' {
    rename `var' `var'_stn
}
tempfile stn_comp
save `stn_comp'

use `comp', clear
bysort tkr: keep if _n == 1
drop if missing(tkr)
drop cusip tin
foreach var in `varlist' {
    rename `var' `var'_tkr
}
tempfile tkr_comp
save `tkr_comp'

use `comp', clear
bysort cusip: keep if _n == 1
drop tkr tin
foreach var in `varlist' {
    rename `var' `var'_cusip
}
tempfile cusip_comp
save `cusip_comp'

/******************************************************
* Merging Data
******************************************************/
use "GaelK.Bertrand/Replication exercise STATA/Output/Temporary/temp_BKS_oil_post_KM_reg_setup.dta", clear

merge m:1 tin using `tin_comp'
rename _merge tin_merge

merge m:1 stn_name using `stn_comp'
rename _merge stn_merge

merge m:1 tkr using `tkr_comp'
rename _merge tkr_merge

merge m:1 cusip using `cusip_comp', update
rename _merge cusip_merge

/******************************************************
* Copying Variables from Merge Files
******************************************************/
foreach i of local varlist {
    gen      `i' = `i'_tin
    replace  `i' = `i'_stn   if missing(`i') & ~missing(`i'_stn)
    replace  `i' = `i'_tkr   if missing(`i') & ~missing(`i'_tkr)
    replace  `i' = `i'_cusip if missing(`i') & ~missing(`i'_cusip)
}

/* Drop unnecessary variables, compress data */
drop cusip_merge tkr_merge stn_merge tin_merge  d_LIAB_* d_ASSETS_* d_EQUITY_* d_STOCK_* d_LEVRATIO_* d_EMP_* d_DIV_*
drop if missing(bhc)
compress
