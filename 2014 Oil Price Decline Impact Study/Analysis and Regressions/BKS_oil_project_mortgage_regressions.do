cd "/classified/l1jrk0b_l1rmb01/Temporary_Files"
capture log close
log using mortgage_regs, replace

local varlist tot toto port porto gov govo portj portjo portnj portnjo nport nportnj nportnjo nporto 
local bank_controls  lag_logdeltares lag_logdeltambs  ln_assets_mean roa_mean foreign npl_share_comm_mean tier1rwa_share_mean ci_share_mean loan_share_mean res_share_mean deposit_share_mean e_share co_share_mean 
local county_controls lnpop lndens percvet lnhdens percenturbanhousingunits percocchousunits percvac lnhvalue lnrent frac3plus personsinpoverty disabled1864civilnoninstl unemploymentrate16 lnhhi
local bank_controls_agg  lag_logdeltares_agg lag_logdeltambs_agg  ln_assets_mean_agg roa_mean_agg foreign_agg npl_share_comm_mean_agg tier1rwa_share_mean_agg ci_share_mean_agg loan_share_mean_agg res_share_mean_agg deposit_share_mean_agg e_share co_share_mean_agg 
local pricelist ltv fico dtib

xtset county_fips

*Aggregate regressions
eststo agg1:   reg d_aggy14po   exposure_county `bank_controls_agg' `county_controls' i.st_code   if fips_tag == 1, robust
               estadd local BC         "Yes ",  replace:    agg1
               estadd local FE         "State", replace:    agg1
	       estadd local CC         "Yes", replace:      agg1	      
eststo agg2:   reg d_aggy14p    exposure_county `bank_controls_agg' `county_controls' i.st_code    if fips_tag == 1, robust
               estadd local BC         "Yes ",  replace:    agg2
               estadd local FE         "State", replace:    agg2
	       estadd local CC         "Yes", replace:      agg2
eststo agg3:   reg d_aggy14t    exposure_county `bank_controls_agg' `county_controls' i.st_code    if fips_tag == 1, robust
               estadd local BC         "Yes ",  replace:    agg3
               estadd local FE         "State", replace:    agg3
	       estadd local CC         "Yes", replace:      agg3
eststo agg4:   reg d_agg        exposure_county `bank_controls_agg' `county_controls' i.st_code    if fips_tag == 1, robust
               estadd local BC         "Yes ",  replace:    agg4
               estadd local FE         "State", replace:    agg4
	       estadd local CC         "Yes", replace:      agg4

egen st_county = group(st_code county_fips)

*Main FE Regressions*
foreach i of local varlist {
eststo fe_`i':  xtivreg2 d_`i'    share211_1213_committed   `bank_controls'                             if first_obs == 1, fe   i(county_fips) cluster(id_rssd county_fips)
                qui areg d_`i'    share211_1213_committed   `bank_controls'                             if first_obs == 1, absorb(county_fips) 
	        scalar r2_areg = e(r2)
		scalar N_areg  = e(N)  
	        estadd local BC         "Yes ",  replace:    fe_`i'
	        estadd local FE         "County",  replace:  fe_`i'
		estadd scalar r2_tot = r2_areg,  replace:    fe_`i'
		estadd scalar N_tot  = N_areg,   replace:    fe_`i' 
eststo ols_`i': ivreg2   d_`i'    share211_1213_committed   `bank_controls' `county_controls' i.st_code if first_obs == 1, cluster(id_rssd st_county)   
                estadd local BC         "Yes ",  replace:    ols_`i'
	        estadd local FE         "State",  replace:   ols_`i'
	        estadd local CC         "Yes",  replace:     ols_`i'
}

*****ROBUSTNESS TO ALTERNATIVE MEASAURES*****
foreach i of local varlist {
eststo fe_`i'L:  xtivreg2 d_`i'   share211_1213_totloans   `bank_controls'                             if first_obs == 1, fe   i(county_fips) cluster(id_rssd county_fips)
                qui areg d_`i'    share211_1213_totloans   `bank_controls'                             if first_obs == 1, absorb(county_fips) 
	        scalar r2_areg = e(r2)
		scalar N_areg  = e(N)  
	        estadd local BC         "Yes ",  replace:    fe_`i'L
	        estadd local FE         "County",  replace:  fe_`i'L
		estadd scalar r2_tot = r2_areg,  replace:    fe_`i'L
		estadd scalar N_tot  = N_areg,   replace:    fe_`i'L 
eststo fe_`i'A:  xtivreg2 d_`i'   share211_1213_totassets   `bank_controls'                             if first_obs == 1, fe   i(county_fips) cluster(id_rssd county_fips)
                qui areg d_`i'    share211_1213_totassets   `bank_controls'                             if first_obs == 1, absorb(county_fips) 
	        scalar r2_areg = e(r2)
		scalar N_areg  = e(N)  
	        estadd local BC         "Yes ",  replace:    fe_`i'A
	        estadd local FE         "County",  replace:  fe_`i'A
		estadd scalar r2_tot = r2_areg,  replace:    fe_`i'A
		estadd scalar N_tot  = N_areg,   replace:    fe_`i'A 
eststo fe_`i'E:  xtivreg2 d_`i'   share211_1213_equity   `bank_controls'                             if first_obs == 1, fe   i(county_fips) cluster(id_rssd county_fips)
                qui areg d_`i'    share211_1213_equity   `bank_controls'                             if first_obs == 1, absorb(county_fips) 
	        scalar r2_areg = e(r2)
		scalar N_areg  = e(N)  
	        estadd local BC         "Yes ",  replace:    fe_`i'E
	        estadd local FE         "County",  replace:  fe_`i'E
		estadd scalar r2_tot = r2_areg,  replace:    fe_`i'E
		estadd scalar N_tot  = N_areg,   replace:    fe_`i'E 		
}


*FICO, LTV, DTIB Regressions
foreach l in new old full {
foreach k in j nj all {
foreach i of local pricelist {
eststo fe_`i'`k'`l' :  qui xtivreg2 d_`i'_`l'`k'    share211_1213_committed   `bank_controls'  d_`i'_lag_`l'`k'                           if first_obs == 1, fe   i(county_fips) cluster(id_rssd county_fips)
                qui areg            d_`i'_`l'`k'    share211_1213_committed   `bank_controls'  d_`i'_lag_`l'`k'                           if first_obs == 1, absorb(county_fips) 
	        scalar r2_areg = e(r2)
		scalar N_areg  = e(N)  
	        estadd local BC         "Yes ",  replace:    fe_`i'`k'`l'
	        estadd local FE         "County",  replace:  fe_`i'`k'`l'
		estadd scalar r2_tot = r2_areg,  replace:    fe_`i'`k'`l'
		estadd scalar N_tot  = N_areg,   replace:    fe_`i'`k'`l'
}
}
}

**********************Wild CLUSTER BOOTSTRAP*******
use "/classified/l1jrk0b_l1rmb01/Output/Temporary/mortgage_countylev", clear
drop if missing(d_toto)
egen banktag = tag(bhc)  


  *Choose exposure variable
   local expose equity
   *local expose committed
    
set more off
xtset county_fips
local dependent tot toto port porto gov govo portj portjo portnj portnjo nport nportnj nportnjo nporto 
local bank_controls  lag_logdeltares lag_logdeltambs  ln_assets_mean roa_mean foreign npl_share_comm_mean tier1rwa_share_mean ci_share_mean loan_share_mean res_share_mean deposit_share_mean e_share co_share_mean 
     
postutil clear

global bootreps = 2000
tempfile main main2 bootsave 
qui save `main2' , replace  

***equity stores equity exposure results*****
*qui postfile indkeep pctile_t_wild str20 dep   using  "/classified/l1jrk0b_l1rmb01/Output/Temporary/permute_storewild_mortequity.dta" , replace
qui postfile indkeep pctile_t_wild str20 dep   using  "/classified/l1jrk0b_l1rmb01/Output/Temporary/permute_storewild_mort.dta" , replace

foreach i of local dependent {
qui areg d_`i'   share211_1213_`expose'   `bank_controls'                             if first_obs == 1, absorb(county_fips) cluster(id_rssd)
global mainbeta = _b[share211_1213_`expose'] 
global maint    = _b[share211_1213_`expose'] / _se[share211_1213_`expose']
predict epshat , resid
predict yhat , xb  

/* also generate "impose the null hypothesis" yhat and residual */
qui areg  d_`i'     `bank_controls'                             if first_obs == 1, absorb(county_fips) 
predict epshat_imposed , resid
predict yhat_imposed , xb 

sort bhc
qui save `main' , replace 

cap erase `bootsave'
qui postfile bskeep t_wild using `bootsave' , replace

set seed 365476247 
forvalues b = 1/$bootreps { 
use `main', replace 
*WILD CLUSTER BOOTSTRAP
qui by bhc: gen temp = uniform() 
qui by bhc: gen pos = (temp[1] < .5) 
qui  gen wildresid = epshat_imposed*(2*pos - 1) 
qui  gen wildy = yhat_imposed + wildresid 
qui areg wildy  share211_1213_`expose'   `bank_controls'                             if first_obs == 1, absorb(county_fips) cluster(id_rssd)
local bst_wild = _b[share211_1213_`expose'] /_se[share211_1213_`expose'] 
qui  post bskeep (`bst_wild') 
} 
qui postclose bskeep 
qui drop _all 

qui set obs 1 
gen t_wild = $maint 
qui  qui append using `bootsave' 

qui gen n = . 
qui summ t_wild 
global bign = r(N) 
qui  sort t_wild 
qui replace n = _n 
qui summ n if abs(t_wild - $maint) < .000001 
global myp = r(mean)/$bign 
global pctile_t_wild = 2*min($myp,(1-$myp)) 
local dep  "`i'"
disp "`i'"
post indkeep ($pctile_t_wild) ("`dep'") 
use `main2', replace
}
postclose indkeep


*** LINE REDACTED DUE TO CONFIDENTIAL INFORMATION

*** LINE REDACTED DUE TO CONFIDENTIAL INFORMATION
*************************************
*** LINE REDACTED DUE TO CONFIDENTIAL INFORMATION



*Summary Stats*
areg d_tot    share211_1213_committed   `bank_controls'                             if first_obs == 1, absorb(county_fips) 
sum  d_tot d_toto d_port d_porto d_gov d_govo d_portj d_portjo d_portnj d_portnjo d_nport d_nportnj d_nportnjo d_nporto  if e(sample)





log close


