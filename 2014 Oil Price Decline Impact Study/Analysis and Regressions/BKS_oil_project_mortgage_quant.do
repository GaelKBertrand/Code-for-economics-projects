set more off
use "/classified/l1jrk0b_l1rmb01/Raw_data/STATA/y14m_mortgage_10pct_11142016.dta", clear

*** LINE REDACTED DUE TO CONFIDENTIAL INFORMATION

**** merge in oil exposure variable
sort id_rssd
merge m:1 id_rssd using "/classified/l1jrk0b_l1rmb01/Output/Temporary/bank_data.dta" //Made in BKS_bankcharact_table.do
keep if _merge==3
drop _merge

**** identify loans with data problems / outliers
gen dropflag = 0
replace dropflag = 1 if orig_date>yq(2016,2)
replace dropflag = 1 if (date - orig_date > 240)
*** LINE REDACTED DUE TO CONFIDENTIAL INFORMATION

label var as_of_mon_id "Reporting date"
label var loan_amt_orig "Loan amount at origination, dollars"

***** drop missing location, loan amounts, winsorize
drop if missing(prop_zip)
drop if missing(loan_amt_orig)
drop if missing(prin_bal_amt)
winsor prin_bal_amt,  gen(balance_wins) p(.01)
winsor loan_amt_orig, gen(origination_wins) p(.01)


***** merge in county codes
destring prop_zip, replace
drop if missing(prop_zip)
sort prop_zip
merge m:1 prop_zip using "/classified/l1jrk0b_l1rmb01/Output/Temporary/zipcode_county_crosswalk.dta"
keep if _merge==3
drop _merge

*Merge in Networth Variables (Created in BKS_oil_project_KM_moodys.do)
capture drop _merge
sort bhc
merge bhc using "/classified/l1jrk0b_l1rmb01/Output/oil_exposure_index/stock_prices.dta"


********** merge in conforming loan limits by year and county

***** first merge in pre-2008 loan limits that vary only by unit number 
capture drop _merge
gen year = year(dofq(orig_date))
sort year
merge m:1 year using /classified/l1jrk0b_l1rmb01/Data/ConformingLoanLimits/pre2008loanlimits.dta
drop _merge

****** merge in 2008 loan limits based on partial county list (i.e., excludes counties with no super jumbo category)
sort year county_fips
merge m:1 year county_fips using /classified/l1jrk0b_l1rmb01/Data/ConformingLoanLimits/loanlimits_2008.dta
drop _merge

********* merge in post-2008 loan limits that vary by unit size and county from full county list
sort year county_fips
merge m:1 year county_fips using /classified/l1jrk0b_l1rmb01/Data/ConformingLoanLimits/post2008loanlimits.dta
drop _merge


****** unify variable names for number of units across different merging data sets
replace oneunitlimit = one if year <= 2007
replace twounitlimit = two if year <= 2007
replace threeunitlimit = three if year <= 2007
replace fourunitlimit = four if year <= 2007
drop one-four

**** hardcode limits for counties not included in the 2008 file
replace oneunitlimit = 417000 if year ==2008 & unitone == .
replace twounitlimit = 533850 if year ==2008 & unittwo == .
replace threeunitlimit = 645300 if year ==2008 & unitthree == .
replace fourunitlimit = 801950 if year ==2008 & unitfour == .

replace oneunitlimit = unitone if year ==2008 & unitone !=.
replace twounitlimit = unittwo if year ==2008 & unittwo !=.
replace threeunitlimit = unitthree if year ==2008 & unitthree !=.
replace fourunitlimit = unitfour if year ==2008 & unitfour !=.
drop unitone - unitfour

******* base jumbo definition on conforming loan limits from HUD data

gen jumbo = 0
replace jumbo = 1 if origination_wins > oneunitlimit & units_no == "1"
replace jumbo = 1 if origination_wins > twounitlimit & units_no == "2"
replace jumbo = 1 if origination_wins > threeunitlimit & units_no == "3"
replace jumbo = 1 if origination_wins > fourunitlimit & units_no == "4"

***** adjust jumbo definition for high cost areas in pre-2008 data
gen highcost = sas_state_abbr_nm == "AK" | sas_state_abbr_nm == "GU" | sas_state_abbr_nm == "HI" | sas_state_abbr_nm == "VI" 
replace jumbo = 0 if origination_wins <= 1.5*oneunitlimit & units_no == "1" & highcost == 1 & year <= 2007
replace jumbo = 0 if origination_wins <= 1.5*twounitlimit & units_no == "2" & highcost == 1 & year <= 2007
replace jumbo = 0 if origination_wins <= 1.5*threeunitlimit & units_no == "3" & highcost == 1 & year <= 2007
replace jumbo = 0 if origination_wins <= 1.5*fourunitlimit & units_no == "4" & highcost == 1 & year <= 2007

*** assign missing values to pre-1980 data & missing units information 
replace jumbo = . if year< 1980
replace jumbo = . if units_no == "Y" | units_no == "U"
label var jumbo "Origination amount above county conforming loan limit"

****Create fraction not-current or pastdue
drop if mba_stat == "REO" // real estate owned
gen     noncurrent = mba_stat ~= "C" 
gen     past90F = mba_stat == "9" | mba_stat == "F" // Past-due or foreclosed
bysort date county_fips: egen frac_nc  = mean(noncurrent)
bysort date county_fips: egen frac_pdf = mean(past90F)

*Drop all past-due/foreclosed loans
keep if mba_stat == "C" | mba_stat== "3" | mba_stat== "6"

gen pre_period_dot  = date>=yq(2012,3) & date<=yq(2014,2)
gen post_period_dot = date>=yq(2015,1) & date<=yq(2015,3)
replace pre_period_dot  = . if pre_period_dot  == 0
replace post_period_dot = . if post_period_dot  == 0

*gen convent = loan_type == "3" | loan_type == "6"
gen convent = 1
replace convent = 0 if loan_type == "1" | loan_type == "2"
gen convent_dot = convent
replace convent_dot = . if convent == 0
gen new_loan = date == orig_date
gen new_loan_dot = new_loan
replace new_loan_dot = . if new_loan == 0


egen first_obs = tag(id_rssd county_fips)
egen first_obsz = tag(id_rssd prop_zip)

gen     dot20123 = .
replace dot20123 = 1 if date==yq(2012,3)
gen     dot20142 = .
replace dot20142 = 1 if date==yq(2014,2)


egen    date_bank_tag =   tag(id_rssd date)
replace date_bank_tag = . if date_bank_tag == 0
egen    loan_date_tag =   tag(id_rssd county_fips date)
replace loan_date_tag = . if loan_date_tag == 0
egen loan_date_tagz = tag(id_rssd prop_zip date)
replace loan_date_tagz = . if loan_date_tagz == 0
egen county_date_tag = tag(county_fips date)
replace county_date_tag = . if county_date_tag == 0

gen gov       = loan_type == "1" | loan_type == "2"
gen tot       = 1
gen toto      =                                                 (loan_src_type ~= "3" & loan_src_type ~= "4" & loan_src_type ~= "5")
gen porto     = investor_type == "7" & gov == 0               & (loan_src_type ~= "3" & loan_src_type ~= "4" & loan_src_type ~= "5")
gen govo      =                        gov == 1               & (loan_src_type ~= "3" & loan_src_type ~= "4" & loan_src_type ~= "5")
gen portjo    = investor_type == "7" & gov == 0 & jumbo == 1  & (loan_src_type ~= "3" & loan_src_type ~= "4" & loan_src_type ~= "5")
gen portnjo   = investor_type == "7" & gov == 0 & jumbo == 0  & (loan_src_type ~= "3" & loan_src_type ~= "4" & loan_src_type ~= "5")
gen port      = investor_type == "7" & gov == 0  
gen portj     = investor_type == "7" & gov == 0 & jumbo == 1
gen portnj    = investor_type == "7" & gov == 0 & jumbo == 0  
gen nport     = investor_type ~= "7" & gov == 0 
gen nporto    = investor_type ~= "7" & gov == 0               & (loan_src_type ~= "3" & loan_src_type ~= "4" & loan_src_type ~= "5")
gen nportnj   = investor_type ~= "7" & gov == 0 & jumbo == 0
gen nportnjo  = investor_type ~= "7" & gov == 0 & jumbo == 0  & (loan_src_type ~= "3" & loan_src_type ~= "4" & loan_src_type ~= "5") 




****************AGGREGATE*****************
***************merge in LPS aggregate data
rename prin_bal_amt prin_bal_amty14
sort   date county_fips
merge  date county_fips  using "/classified/l1jrk0b_l1rmb01/Data/lps_10pct_ransample_counties.dta"
drop _merge
rename prin_bal_amt prin_bal_amtlps
************************
bysort county_fips                :  egen pre_oil_loans   = mean(prin_bal_amtlps*pre_period_dot*county_date_tag)
bysort county_fips                :  egen post_oil_loans  = mean(prin_bal_amtlps*post_period_dot*county_date_tag)
gen d_agg = ln(post_oil_loans / pre_oil_loans)
drop pre_oil_loans  post_oil_loans 

bysort id_rssd county_fips date:  egen loans_date      = total(balance_wins*porto), missing
bysort id_rssd county_fips     :  egen pre_oil_loans   = mean(loans_date*pre_period_dot*loan_date_tag) 
local bank_controls delta_price delta_mcap share211_1213_committed  lag_logdeltares lag_logdeltambs  ln_assets_mean roa_mean foreign npl_share_comm_mean tier1rwa_share_mean ci_share_mean loan_share_mean res_share_mean deposit_share_mean e_share co_share_mean 
foreach j of local bank_controls {
bysort county_fips: egen `j'_agg = wtmean(`j'), weight(pre_oil_loans) 
}
drop loans_date pre_oil_loans 
rename share211_1213_committed_agg exposure_county

bysort county_fips date:  egen loans_date      = total(balance_wins*porto), missing
bysort county_fips     :  egen pre_oil_loans   = mean(loans_date*pre_period_dot*county_date_tag)
bysort county_fips     :  egen post_oil_loans   = mean(loans_date*post_period_dot*county_date_tag)
gen d_aggy14po = ln(post_oil_loans / pre_oil_loans)
drop loans_date pre_oil_loans post_oil_loans 


bysort county_fips date:  egen loans_date      = total(balance_wins*port), missing
bysort county_fips     :  egen pre_oil_loans   = mean(loans_date*pre_period_dot*county_date_tag)
bysort county_fips     :  egen post_oil_loans   = mean(loans_date*post_period_dot*county_date_tag)
gen d_aggy14p = ln(post_oil_loans / pre_oil_loans)
drop loans_date pre_oil_loans post_oil_loans 

bysort county_fips date:  egen loans_date      = total(balance_wins), missing
bysort county_fips     :  egen pre_oil_loans   = mean(loans_date*pre_period_dot*county_date_tag)
bysort county_fips     :  egen post_oil_loans  = mean(loans_date*post_period_dot*county_date_tag)
gen d_aggy14t = ln(post_oil_loans / pre_oil_loans)
drop loans_date pre_oil_loans post_oil_loans 



**********************************************

*****CREATE DEPENDENT VARIABLES***********************
local varlist tot toto port porto gov govo portj portjo portnj portnjo nport nportnj nportnjo nporto 
foreach i of local varlist {
bysort id_rssd county_fips date:  egen loans_date      = total(balance_wins*`i' ), missing
bysort id_rssd county_fips     :  egen pre_oil_loans   = mean(loans_date*pre_period_dot*loan_date_tag)
by     id_rssd county_fips     :  egen post_oil_loans  = mean(loans_date*post_period_dot*loan_date_tag)
gen d_`i'     = ln(post_oil_loans / pre_oil_loans)
drop loans_date pre_oil_loans post_oil_loans
}


******Merge in 2013 employee compensation shares from O&G extraction and Support Activities for O&G (BEA Tables CA6N: Compensation of Employees By Industry)***************
tostring county_fips, gen(fips)
replace fips = "0" + fips if strlen(fips) == 4
capture drop _merge
sort fips
merge fips using "/classified/l1jrk0b_l1rmb01/Data/shareOG_BEA.dta"
replace shareOG = 0 if missing(shareOG)

bysort 	bhc:	egen	tot_porto_pre	        = total(balance_wins*porto*pre_period_dot), missing
by  	bhc:	egen	tot_porto_pre211_0	= total(balance_wins*porto*pre_period_dot*(shareOG>0)), missing
by 	bhc:	egen	tot_porto_pre211_10	= total(balance_wins*porto*pre_period_dot*(shareOG>0.1)), missing
by  	bhc:	egen	tot_porto_pre211_wt	= total(balance_wins*porto*pre_period_dot*shareOG), missing
		gen	exposure_0	= tot_porto_pre211_0/tot_porto_pre
		gen	exposure_10	= tot_porto_pre211_10/tot_porto_pre
		gen	exposure_wt	= tot_porto_pre211_wt/tot_porto_pre

compress


