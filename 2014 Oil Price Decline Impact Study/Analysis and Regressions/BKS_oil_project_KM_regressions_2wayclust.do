/* BKS_oil_project_KM_regressions.do performs the regression analysis for the KM study using a 2-way clustering approach. */

set	more off
cd	"/classified/l1jrk0b_l1rmb01/Output"
capture log close
log 	using BKS_oil_project_results, replace

*** JK edit: update data but preserve original estimation sample
drop if date>222 
*Choose Winsor Levels and Weights 
local winsor_lhs    .01   //Dependent variable winsor level
local winsor_weight .01   //Weight winsor level
local reg_weight   noweight //  Choose whether we are weighting the regessions: either noweight, winsorweight, oldweight

*DROP ALL 211 firms
drop if ind3 == "211"

*Replace size interaction to continuous
*gen lnfirmsize = ln(size)
*replace inter_size = share211_1213_committed*lnfirmsize

*Local controls
local bank_controlsagg      lag_logdeltaci_agg  e_share_agg ln_assets_agg  roa_agg   foreign npl_share_comm_agg  tier1rwa_share_agg  ci_share_agg   loan_share_agg  res_share_agg  deposit_share_agg    co_share_agg
local bank_controls         lag_logdeltaci      e_share     ln_assets_mean roa_mean  foreign npl_share_comm_mean tier1rwa_share_mean ci_share_mean  loan_share_mean res_share_mean deposit_share_mean   co_share_mean


local loan_controls      avg_age_termall age2 age3  
local loan_controlsagg   avg_age_agg_termall ageagg2 ageagg3  
*local firm_controls     ext openlinepre risky_pre multi_bank4
local firm_controls      multi_bank
local intersmall         inter_size small_size 
*local intersmall         inter_size lnfirmsize 

local interrisky         inter_risky risky_pre 
local interext           inter_ext ext
local interold           inter_old old
local intermulti         inter_multib4 multi_bank4
local interallols        inter_ext ext inter_open  openlinepre    inter_multib4 multi_bank4   
local interallfe         inter_ext     inter_open                 inter_multib4                       



*Winsorize Dependendent Variable
gen samp = .
replace samp = 1 if f_km_loan_termall & ~missing(d_km_l_loan_termall) & balance == 1 
gen loan_samp = samp*d_km_l_loan_termall
winsor loan_samp, gen(wins1) p(`winsor_lhs')
drop d_km_l_loan_termall loan_samp samp
gen d_km_l_loan_termall = wins1
drop wins1 

*Winsorize Weights
gen samp = .
replace samp = 1 if f_km_loan_termall 
gen loan_samp = samp*km_loan_bef_termall
winsor loan_samp, gen(wins1) p(`winsor_weight')
drop loan_samp samp
gen weight_bef = wins1
drop wins1 

gen samp = .
replace samp = 1 if f_km_loan_termall 
gen loan_samp = samp*km_loan_aft_termall
winsor loan_samp, gen(wins1) p(`winsor_weight')
drop  loan_samp samp
gen weight_aft = wins1
drop wins1

*Weighting or no Weighting
if "`reg_weight'" == "noweight" {
replace weight_bef = 1  
replace weight_aft = 1  
}
else if "`reg_weight'" == "winsorweight"  {
replace weight_bef =  weight_bef  
replace weight_aft =  weight_aft  
}
else if "`reg_weight'" == "oldweight"  {
replace weight_bef =  km_loan_bef_termall  
replace weight_aft =  km_loan_aft_termall  
}



****Summary Stats***
/*
winsor assets if first_tin_dot == 1, gen(assets_win) p(0.05)
bysort tincode: egen assets_winm = max(assets_win)
xtset tincode
areg d_km_l_loan_termall      share211_1213_committed    `loan_controls' `bank_controls'    if f_km_loan_termall == 1  & termall_multi_km  == 1      & balance == 1                                        , absorb(tincode) 
gen int_fe  = e(sample)
areg d_km_l_loan_termall      share211_1213_committed                  `loan_controls' `bank_controls' `firm_controls'  if f_km_loan_termall == 1                                            & substr(ind3, 1,3) ~= "211" & balance == 1, absorb(zipind)  
gen int_ols = e(sample)
areg  termall_km_exit         share211_1213_committed                                  `bank_controls'                           if f_km_loan_termall == 1  & termall_multi_km_bef == 1                                           , absorb(tincode) 
gen ex_fe  =  e(sample)
areg termall_km_exit         share211_1213_committed                                  `bank_controls' `firm_controls'                        if f_km_loan_termall == 1                                           & substr(ind3, 1,3) ~= "211" , absorb(zipind)    
gen ex_ols = e(sample)
areg  termall_km_entry         share211_1213_committed                                  `bank_controls'                                  if f_km_loan_termall == 1  & termall_multi_km_aft == 1                                           , absorb(tincode) 
gen ent_fe = e(sample)
areg termall_km_entry         share211_1213_committed                                  `bank_controls' `firm_controls'                        if f_km_loan_termall == 1                                           & substr(ind3, 1,3) ~= "211" , absorb(zipind)    
gen ent_ols = e(sample)

local var int ex ent  
local var2 fe ols 
foreach i of local var {
foreach j of local var2{
bysort tincode `i'_`j':  gen `i'_tin_`j' = _n == 1 
replace `i'_tin_`j'  = 0 if `i'_`j' == 0
}
}

unique(tincode) if int_fe
unique(tincode) if int_ols
unique(tincode) if ex_fe
unique(tincode) if ex_ols
unique(tincode) if ent_fe
unique(tincode) if ent_ols

sum assets_winm ext numbankspre share_bef small_size if int_fe == 1  & int_tin_fe == 1
sum assets_winm ext numbankspre share_bef small_size if int_ols == 1 & int_tin_ols == 1
sum assets_winm ext numbankspre share_bef small_size if ex_fe == 1  & ex_tin_fe == 1
sum assets_winm ext numbankspre share_bef small_size if ex_ols == 1 & ex_tin_ols == 1
sum assets_winm ext numbankspre share_bef small_size if ent_fe == 1  & ent_tin_fe == 1
sum assets_winm ext numbankspre share_bef small_size if ent_ols == 1 & ent_tin_ols == 1

sum d_km_l_loan_termall termall_km_exit termall_km_entry old km_loan_bef_termall   if int_fe == 1 
sum d_km_l_loan_termall termall_km_exit termall_km_entry old km_loan_bef_termall   if int_ols == 1 
sum d_km_l_loan_termall termall_km_exit termall_km_entry old km_loan_bef_termall   if ex_fe == 1 
sum d_km_l_loan_termall termall_km_exit termall_km_entry old km_loan_bef_termall   if ex_ols == 1 
sum d_km_l_loan_termall termall_km_exit termall_km_entry old  if ent_fe == 1 
sum d_km_l_loan_termall termall_km_exit termall_km_entry old  if ent_ols == 1 
*/

**Variance correction for bias corrections**
/*
xtivreg2 d_km_l_agg_termall exposure_agg_termall `loan_controlsagg'  `bank_controlsagg' `firm_controls'   if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" , fe i(zipind)   robust
sum exposure_agg_termall if e(sample)
sum share211_1213_committed if int_fe 
sum share211_1213_committed if int_ols 
*/

*** LINE REDACTED DUE TO CONFIDENTIAL INFORMATION

*************************************

************ROBUSTNESS: LCR*******
/*
gen big = assets_mean > 250000000
gen big_lcr = big*lcr_proxy_mean 
local bank_controls2     big big_lcr lcr_proxy_mean    lag_logdeltaci      e_share      roa_mean  foreign npl_share_comm_mean tier1rwa_share_mean ci_share_mean  loan_share_mean res_share_mean deposit_share_mean   co_share_mean
xtset tincode
xtivreg2  d_km_l_loan_termall     share211_1213_committed                `loan_controls' `bank_controls2'                  [aw = weight_bef]  if f_km_loan_termall == 1  & termall_multi_km  == 1      & balance == 1                                        , fe i(tincode) cluster(bhc tincode)
*/
***************************************

************ROBUSTNESS: OUTLIER BANK*****
*** LINE REDACTED DUE TO CONFIDENTIAL INFORMATION

**********************************************

************ROBUSTNESS: CONTROL INCLUSION*****
/*
xtset tincode                            
local bank_controls1         lag_logdeltaci    ln_assets_mean foreign
local bank_controls2         lag_logdeltaci    ln_assets_mean foreign npl_share_comm_mean co_share_mean roa_mean
local bank_controls3         lag_logdeltaci    ln_assets_mean foreign npl_share_comm_mean co_share_mean roa_mean e_share tier1rwa_share_mean
local bank_controls4         lag_logdeltaci    ln_assets_mean foreign npl_share_comm_mean co_share_mean roa_mean e_share tier1rwa_share_mean deposit_share_mean ci_share_mean loan_share_mean res_share_mean

eststo feintens2_rob0:  xtivreg2  d_km_l_loan_termall     share211_1213_committed                `loan_controls'                                   [aw = weight_bef]  if f_km_loan_termall == 1  & termall_multi_km  == 1      & balance == 1                                        , fe i(tincode) cluster(bhc tincode)
eststo feintens2_rob1:  xtivreg2  d_km_l_loan_termall     share211_1213_committed                `loan_controls' `bank_controls1'                  [aw = weight_bef]  if f_km_loan_termall == 1  & termall_multi_km  == 1      & balance == 1                                        , fe i(tincode) cluster(bhc tincode)
eststo feintens2_rob2:  xtivreg2  d_km_l_loan_termall     share211_1213_committed                `loan_controls' `bank_controls2'                  [aw = weight_bef]  if f_km_loan_termall == 1  & termall_multi_km  == 1      & balance == 1                                        , fe i(tincode) cluster(bhc tincode)
eststo feintens2_rob3:  xtivreg2  d_km_l_loan_termall     share211_1213_committed                `loan_controls' `bank_controls3'                  [aw = weight_bef]  if f_km_loan_termall == 1  & termall_multi_km  == 1      & balance == 1                                        , fe i(tincode) cluster(bhc tincode)
eststo feintens2_rob4:  xtivreg2  d_km_l_loan_termall     share211_1213_committed                `loan_controls' `bank_controls4'                  [aw = weight_bef] if f_km_loan_termall == 1 & termall_multi_km == 1 & balance == 1 , fe i(tincode) cluster(bhc tincode)

eststo feexit2_rob0:   xtivreg2  termall_km_exit         share211_1213_committed                                                                    [aw = weight_bef]                    if f_km_loan_termall == 1  & termall_multi_km_bef == 1                                           , fe i(tincode) cluster(bhc tincode)
eststo feexit2_rob1:   xtivreg2  termall_km_exit         share211_1213_committed                                  `bank_controls1'                  [aw = weight_bef]                    if f_km_loan_termall == 1  & termall_multi_km_bef == 1                                           , fe i(tincode) cluster(bhc tincode)
eststo feexit2_rob2:   xtivreg2  termall_km_exit         share211_1213_committed                                  `bank_controls2'                  [aw = weight_bef]                    if f_km_loan_termall == 1  & termall_multi_km_bef == 1                                           , fe i(tincode) cluster(bhc tincode)
eststo feexit2_rob3:   xtivreg2  termall_km_exit         share211_1213_committed                                  `bank_controls3'                  [aw = weight_bef]                    if f_km_loan_termall == 1  & termall_multi_km_bef == 1                                           , fe i(tincode) cluster(bhc tincode)
eststo feexit2_rob4:   xtivreg2  termall_km_exit         share211_1213_committed                                  `bank_controls4'                  [aw = weight_bef]                    if f_km_loan_termall == 1  & termall_multi_km_bef == 1                                           , fe i(tincode) cluster(bhc tincode)
*/


xtset tincode
*KM Regressions

eststo feintens1:  xtivreg2 d_km_l_loan_termall     share211_1213_committed                 `loan_controls'                                  [aw = weight_bef]  if f_km_loan_termall == 1  & termall_multi_km  == 1      & balance == 1                                        , fe i(tincode) cluster(bhc tincode)
                   qui areg d_km_l_loan_termall     share211_1213_committed                 `loan_controls'                                  [aw = weight_bef]  if f_km_loan_termall == 1  & termall_multi_km  == 1      & balance == 1                                        , absorb(tincode) 
                   scalar r2_areg = e(r2)
		   scalar N_areg  = e(N)
		   estadd local FE        "Firm",   replace:    feintens1
		   estadd scalar r2_tot = r2_areg,  replace:    feintens1
		   estadd scalar N_tot  = N_areg,   replace:    feintens1                         
eststo feintens2:  xtivreg2  d_km_l_loan_termall     share211_1213_committed                `loan_controls' `bank_controls'                  [aw = weight_bef]  if f_km_loan_termall == 1  & termall_multi_km  == 1      & balance == 1                                        , fe i(tincode) cluster(bhc tincode)
                   qui areg  d_km_l_loan_termall     share211_1213_committed                `loan_controls' `bank_controls'                  [aw = weight_bef]  if f_km_loan_termall == 1  & termall_multi_km  == 1      & balance == 1                                        , absorb(tincode) 
                   scalar r2_areg = e(r2)
		   scalar N_areg  = e(N)
		   estadd local FE         "Firm",  replace:    feintens2
		   estadd scalar r2_tot = r2_areg,  replace:    feintens2 
		   estadd scalar N_tot  = N_areg,   replace:    feintens2   
eststo feintens2L: xtivreg2  d_km_l_loan_termall    share211_1213_totloans                `loan_controls' `bank_controls'                  [aw = weight_bef]  if f_km_loan_termall == 1  & termall_multi_km  == 1      & balance == 1                                        , fe i(tincode) cluster(bhc tincode)
                   qui areg  d_km_l_loan_termall     share211_1213_totloans                `loan_controls' `bank_controls'                  [aw = weight_bef]  if f_km_loan_termall == 1  & termall_multi_km  == 1      & balance == 1                                        , absorb(tincode) 
                   scalar r2_areg = e(r2)
		   scalar N_areg  = e(N)
		   estadd local FE         "Firm",  replace:    feintens2L
		   estadd scalar r2_tot = r2_areg,  replace:    feintens2L 
		   estadd scalar N_tot  = N_areg,   replace:    feintens2L 
eststo feintens2A: xtivreg2  d_km_l_loan_termall    share211_1213_totassets                `loan_controls' `bank_controls'                  [aw = weight_bef]  if f_km_loan_termall == 1  & termall_multi_km  == 1      & balance == 1                                        , fe i(tincode) cluster(bhc tincode)
                   qui areg  d_km_l_loan_termall    share211_1213_totassets                `loan_controls' `bank_controls'                  [aw = weight_bef]  if f_km_loan_termall == 1  & termall_multi_km  == 1      & balance == 1                                        , absorb(tincode) 
                   scalar r2_areg = e(r2)
		   scalar N_areg  = e(N)
		   estadd local FE         "Firm",  replace:    feintens2A
		   estadd scalar r2_tot = r2_areg,  replace:    feintens2A 
		   estadd scalar N_tot  = N_areg,   replace:    feintens2A
eststo feintens2E: xtivreg2  d_km_l_loan_termall    share211_1213_equity                   `loan_controls' `bank_controls'                  [aw = weight_bef]  if f_km_loan_termall == 1  & termall_multi_km  == 1      & balance == 1                                        , fe i(tincode) cluster(bhc tincode)
                   qui areg  d_km_l_loan_termall    share211_1213_equity                   `loan_controls' `bank_controls'                  [aw = weight_bef]  if f_km_loan_termall == 1  & termall_multi_km  == 1      & balance == 1                                        , absorb(tincode) 
                   scalar r2_areg = e(r2)
		   scalar N_areg  = e(N)
		   estadd local FE         "Firm",  replace:    feintens2E
		   estadd scalar r2_tot = r2_areg,  replace:    feintens2E 
		   estadd scalar N_tot  = N_areg,   replace:    feintens2E   			    		    
eststo feintens4:  xtivreg2 d_km_l_loan_termall     share211_1213_committed   inter_risky   `loan_controls' `bank_controls'                  [aw = weight_bef]  if f_km_loan_termall == 1  & termall_multi_km  == 1      & balance == 1                                        , fe i(tincode) cluster(bhc tincode)
                   qui areg d_km_l_loan_termall     share211_1213_committed   inter_risky   `loan_controls' `bank_controls'                  [aw = weight_bef]  if f_km_loan_termall == 1  & termall_multi_km  == 1      & balance == 1                                        , absorb(tincode) 
                   scalar r2_areg = e(r2)
		   scalar N_areg  = e(N)
		   estadd local FE  "Firm",         replace:    feintens4
		   estadd scalar r2_tot = r2_areg,  replace:    feintens4
		   estadd scalar N_tot  = N_areg,   replace:    feintens4          		   		    
eststo feintens7:  xtivreg2 d_km_l_loan_termall     share211_1213_committed  `interallfe'   `loan_controls' `bank_controls'                  [aw = weight_bef]  if f_km_loan_termall == 1  & termall_multi_km  == 1      & balance == 1                                        , fe i(tincode) cluster(bhc tincode)
		   qui areg d_km_l_loan_termall     share211_1213_committed  `interallfe'   `loan_controls' `bank_controls'                  [aw = weight_bef]  if f_km_loan_termall == 1  & termall_multi_km  == 1      & balance == 1                                        , absorb(tincode) 
		   scalar r2_areg = e(r2)
	           scalar N_areg  = e(N)
		   estadd local FE  "Firm",         replace:    feintens7
		   estadd scalar r2_tot = r2_areg,  replace:    feintens7
		   estadd scalar N_tot  = N_areg,   replace:    feintens7   
*/
eststo feintens8:  xtivreg2 d_km_l_loan_termall     share211_1213_committed   inter_size    `loan_controls' `bank_controls'                  [aw = weight_bef]  if f_km_loan_termall == 1  & termall_multi_km  == 1      & balance == 1                                        , fe i(tincode) cluster(bhc tincode)
	           qui areg d_km_l_loan_termall     share211_1213_committed   inter_size    `loan_controls' `bank_controls'                  [aw = weight_bef]  if f_km_loan_termall == 1  & termall_multi_km  == 1      & balance == 1                                        , absorb(tincode) 
                   scalar r2_areg = e(r2)
	           scalar N_areg  = e(N)
		   estadd local FE  "Firm",         replace:    feintens8    
		   estadd scalar r2_tot = r2_areg,  replace:    feintens8  
		   estadd scalar N_tot  = N_areg,   replace:    feintens8      

						 
	gen fe_sample_dot = e(sample) 
	xtset zipind           
eststo olsintens1:  ivreg2 d_km_l_loan_termall     share211_1213_committed                  `loan_controls'                                 [aw = weight_bef]  if f_km_loan_termall == 1  & termall_multi_km  == 1 & fe_sample_dot ==1 & substr(ind3, 1,3) ~= "211"  & balance == 1,                 cluster(bhc zipind)
                    scalar r2_areg = e(r2)
		    scalar N_areg  = e(N)
		    estadd scalar r2_tot = r2_areg,  replace:    olsintens1
		    estadd scalar N_tot  = N_areg,   replace:    olsintens1  
eststo olsintens2:  ivreg2 d_km_l_loan_termall     share211_1213_committed                  `loan_controls'                                 [aw = weight_bef]  if f_km_loan_termall == 1                                           & substr(ind3, 1,3) ~= "211"  & balance == 1,                 cluster(bhc zipind)
		    scalar r2_areg = e(r2)
		    scalar N_areg  = e(N)
		    estadd scalar r2_tot = r2_areg,  replace:    olsintens2
		    estadd scalar N_tot  = N_areg,   replace:    olsintens2   

eststo olsintens3:  ivreg2 d_km_l_loan_termall     share211_1213_committed                  `loan_controls' `bank_controls'                 [aw = weight_bef]  if f_km_loan_termall == 1                                           & substr(ind3, 1,3) ~= "211" & balance == 1,                 cluster(bhc zipind)
		    scalar r2_areg = e(r2)
		    scalar N_areg  = e(N)
		    estadd scalar r2_tot = r2_areg,  replace:    olsintens3
		    estadd scalar N_tot  = N_areg,   replace:    olsintens3   
eststo olsintens3s: ivreg2 d_km_l_loan_termall     share211_1213_committed                  `loan_controls' `bank_controls'                 [aw = weight_bef]  if f_km_loan_termall == 1  & termall_multi_km  == 1 & fe_sample_dot ==1 & substr(ind3, 1,3) ~= "211" & balance == 1,                 cluster(bhc zipind)
		    scalar r2_areg = e(r2)
		    scalar N_areg  = e(N)
		    estadd scalar r2_tot = r2_areg,  replace:    olsintens3s
		    estadd scalar N_tot  = N_areg,   replace:    olsintens3s 
eststo olsintens5: xtivreg2 d_km_l_loan_termall     share211_1213_committed   `intersmall'   `loan_controls' `bank_controls' `firm_controls' [aw = weight_bef]  if f_km_loan_termall == 1                                            & substr(ind3, 1,3) ~= "211" & balance == 1, fe i(zipind)  cluster(bhc zipind)
		   qui areg d_km_l_loan_termall     share211_1213_committed   `intersmall'   `loan_controls' `bank_controls' `firm_controls' [aw = weight_bef]  if f_km_loan_termall == 1                                            & substr(ind3, 1,3) ~= "211" & balance == 1, absorb(zipind)  
		   scalar r2_areg = e(r2)
		   scalar N_areg  = e(N)
		   estadd scalar r2_tot = r2_areg,   replace:    olsintens5
		   estadd scalar N_tot  = N_areg,    replace:    olsintens5  
		   estadd local FE  "Firm Controls", replace:    olsintens5
eststo olsintens5s: xtivreg2 d_km_l_loan_termall    share211_1213_committed   `intersmall'   `loan_controls' `bank_controls' `firm_controls' [aw = weight_bef]  if f_km_loan_termall == 1 & termall_multi_km  == 1 & fe_sample_dot ==1  & substr(ind3, 1,3) ~= "211" & balance == 1, fe i(zipind)  cluster(bhc zipind)
		   qui  areg d_km_l_loan_termall    share211_1213_committed   `intersmall'   `loan_controls' `bank_controls' `firm_controls' [aw = weight_bef]  if f_km_loan_termall == 1 & termall_multi_km  == 1 & fe_sample_dot ==1  & substr(ind3, 1,3) ~= "211" & balance == 1, absorb(zipind)  
		   scalar r2_areg = e(r2)
		   scalar N_areg  = e(N)
		   estadd scalar r2_tot = r2_areg,   replace:    olsintens5s
		   estadd scalar N_tot  = N_areg,    replace:    olsintens5s  
		   estadd local FE  "Firm Controls", replace:    olsintens5s
eststo olsintens6: xtivreg2 d_km_l_loan_termall     share211_1213_committed   `interallols'  `loan_controls' `bank_controls' `firm_controls' [aw = weight_bef]  if f_km_loan_termall == 1                                            & substr(ind3, 1,3) ~= "211" & balance == 1 , fe i(zipind)  cluster(bhc zipind)
		   qui areg d_km_l_loan_termall     share211_1213_committed   `interallols'  `loan_controls' `bank_controls' `firm_controls' [aw = weight_bef]  if f_km_loan_termall == 1                                            & substr(ind3, 1,3) ~= "211" & balance == 1 , absorb(zipind)  
		   scalar N_areg  = e(N)
		   scalar r2_areg = e(r2)
		   estadd scalar r2_tot = r2_areg,   replace:    olsintens6
		   estadd scalar N_tot  = N_areg,    replace:    olsintens6 
		   estadd local FE  "Firm Controls",  replace:   olsintens6
eststo olsintens6s: xtivreg2 d_km_l_loan_termall   share211_1213_committed   `interallols'  `loan_controls' `bank_controls' `firm_controls' [aw = weight_bef]  if f_km_loan_termall == 1 & termall_multi_km  == 1 & fe_sample_dot ==1  & substr(ind3, 1,3) ~= "211" & balance== 1 , fe i(zipind)  cluster(bhc zipind)
                   qui areg d_km_l_loan_termall    share211_1213_committed   `interallols'  `loan_controls' `bank_controls' `firm_controls' [aw = weight_bef]  if f_km_loan_termall == 1 & termall_multi_km  == 1 & fe_sample_dot ==1  & substr(ind3, 1,3) ~= "211" & balance== 1 , absorb(zipind)  
                   scalar r2_areg = e(r2)
		   scalar N_areg  = e(N)
		   estadd scalar r2_tot = r2_areg,   replace:    olsintens6s
		   estadd scalar N_tot  = N_areg,    replace:    olsintens6s  
                   estadd local FE  "Firm Controls",  replace:   olsintens6s

*eststo olsintens7: xtivreg2 d_km_l_loan_termall     share211_1213_committed   `interrisky'  `loan_controls' `bank_controls' `firm_controls'  [aw = weight_bef]  if f_km_loan_termall == 1                                            & substr(ind3, 1,3) ~= "211" & balance == 1, fe i(zipind)  cluster(bhc zipind)
*		   qui areg d_km_l_loan_termall     share211_1213_committed   `interrisky'  `loan_controls' `bank_controls' `firm_controls'  [aw = weight_bef]  if f_km_loan_termall == 1                                            & substr(ind3, 1,3) ~= "211" & balance == 1, absorb(zipind)  
*		   scalar r2_areg = e(r2)
*		   scalar N_areg  = e(N)
*		   estadd scalar r2_tot = r2_areg,   replace:    olsintens7
*		   estadd scalar N_tot  = N_areg,    replace:    olsintens7  
*		   estadd local FE  "Firm Controls",  replace:   olsintens7
eststo olsintens10: xtivreg2 d_km_l_loan_termall     share211_1213_committed                  `loan_controls' `bank_controls' `firm_controls' [aw = weight_bef]  if f_km_loan_termall == 1                                            & substr(ind3, 1,3) ~= "211" & balance == 1, fe i(zipind)  cluster(bhc zipind)
                   qui areg  d_km_l_loan_termall     share211_1213_committed                  `loan_controls' `bank_controls' `firm_controls' [aw = weight_bef]  if f_km_loan_termall == 1                                            & substr(ind3, 1,3) ~= "211" & balance == 1, absorb(zipind)   
		   scalar r2_areg = e(r2)
		   scalar N_areg  = e(N)
		   estadd scalar r2_tot = r2_areg,   replace:    olsintens10
		   estadd scalar N_tot  = N_areg,    replace:    olsintens10  
		   estadd local FE  "Firm Controls", replace:    olsintens10
eststo olsintens10s: xtivreg2 d_km_l_loan_termall   share211_1213_committed                  `loan_controls' `bank_controls' `firm_controls' [aw = weight_bef]  if f_km_loan_termall == 1                       & fe_sample_dot ==1 & substr(ind3, 1,3) ~= "211" & balance == 1 , fe i(zipind)  cluster(bhc zipind)
		   qui areg   d_km_l_loan_termall   share211_1213_committed                  `loan_controls' `bank_controls' `firm_controls' [aw = weight_bef]  if f_km_loan_termall == 1                       & fe_sample_dot ==1 & substr(ind3, 1,3) ~= "211" & balance == 1 , absorb(zipind) 
		   scalar r2_areg = e(r2)
		   scalar N_areg  = e(N)
		   estadd scalar r2_tot = r2_areg,   replace:    olsintens10s
		   estadd scalar N_tot  = N_areg,    replace:    olsintens10s  
		   estadd local FE  "Firm Controls", replace:    olsintens10s
eststo olsintens11: xtivreg2 d_km_l_loan_termall     share211_1213_committed   `intermulti'  `loan_controls' `bank_controls' `firm_controls'  [aw = weight_bef]  if f_km_loan_termall == 1                                            & substr(ind3, 1,3) ~= "211" & balance == 1 , fe i(zipind)  cluster(bhc zipind)
	           qui areg d_km_l_loan_termall      share211_1213_committed   `intermulti'  `loan_controls' `bank_controls' `firm_controls'  [aw = weight_bef]  if f_km_loan_termall == 1                                            & substr(ind3, 1,3) ~= "211" & balance == 1 , absorb(zipind)  
		   scalar r2_areg = e(r2)
		   scalar N_areg  = e(N)
		   estadd scalar r2_tot = r2_areg,   replace:    olsintens11
		   estadd scalar N_tot  = N_areg,    replace:    olsintens11  
		   estadd local FE  "Firm Controls",  replace:   olsintens11

xtset tincode
eststo feexit1:   xtivreg2  termall_km_exit         share211_1213_committed                                                                   [aw = weight_bef]                    if f_km_loan_termall == 1  & termall_multi_km_bef == 1                                           , fe i(tincode) cluster(bhc tincode)
                  qui  areg  termall_km_exit        share211_1213_committed                                                                   [aw = weight_bef]                    if f_km_loan_termall == 1  & termall_multi_km_bef == 1                                           , absorb(tincode) 
		  scalar r2_areg = e(r2)
		  scalar N_areg  = e(N)
		  estadd scalar r2_tot = r2_areg,   replace:    feexit1
		  estadd scalar N_tot  = N_areg,    replace:    feexit1
		  estadd local FE_bi  "Yes",        replace:    feexit1
		  estadd local FE  "Firm",          replace:    feexit1  
eststo feexit2:   xtivreg2  termall_km_exit         share211_1213_committed                                  `bank_controls'                  [aw = weight_bef]                    if f_km_loan_termall == 1  & termall_multi_km_bef == 1                                           , fe i(tincode) cluster(bhc tincode)
		  qui    areg  termall_km_exit     share211_1213_committed                                  `bank_controls'                  [aw = weight_bef]                    if f_km_loan_termall == 1  & termall_multi_km_bef == 1                                           , absorb(tincode) 
		  scalar r2_areg = e(r2)
		  scalar N_areg  = e(N)
		  estadd scalar r2_tot = r2_areg,   replace:    feexit2
		  estadd scalar N_tot  = N_areg,    replace:    feexit2
		  estadd local FE_bi  "Yes",        replace:    feexit2
		  estadd local BC_bi  "Yes",        replace:    feexit2
		  estadd local FE  "Firm",          replace:    feexit2 
eststo feexit2L:   xtivreg2    termall_km_exit     share211_1213_totloans                                  `bank_controls'                  [aw = weight_bef]                    if f_km_loan_termall == 1  & termall_multi_km_bef == 1                                           , fe i(tincode) cluster(bhc tincode)
		  qui    areg  termall_km_exit     share211_1213_totloans                                  `bank_controls'                  [aw = weight_bef]                    if f_km_loan_termall == 1  & termall_multi_km_bef == 1                                           , absorb(tincode) 
		  scalar r2_areg = e(r2)
		  scalar N_areg  = e(N)
		  estadd scalar r2_tot = r2_areg,   replace:    feexit2L
		  estadd scalar N_tot  = N_areg,    replace:    feexit2L
		  estadd local FE_bi  "Yes",        replace:    feexit2L
		  estadd local BC_bi  "Yes",        replace:    feexit2L
		  estadd local FE  "Firm",          replace:    feexit2L 
eststo feexit2A:   xtivreg2    termall_km_exit     share211_1213_totassets                                  `bank_controls'                  [aw = weight_bef]                    if f_km_loan_termall == 1  & termall_multi_km_bef == 1                                           , fe i(tincode) cluster(bhc tincode)
		  qui    areg  termall_km_exit     share211_1213_totassets                                 `bank_controls'                  [aw = weight_bef]                    if f_km_loan_termall == 1  & termall_multi_km_bef == 1                                           , absorb(tincode) 
		  scalar r2_areg = e(r2)
		  scalar N_areg  = e(N)
		  estadd scalar r2_tot = r2_areg,   replace:    feexit2A
		  estadd scalar N_tot  = N_areg,    replace:    feexit2A
		  estadd local FE_bi  "Yes",        replace:    feexit2A
		  estadd local BC_bi  "Yes",        replace:    feexit2A
		  estadd local FE  "Firm",          replace:    feexit2A 
eststo feexit2E:   xtivreg2    termall_km_exit     share211_1213_equity                                  `bank_controls'                  [aw = weight_bef]                    if f_km_loan_termall == 1  & termall_multi_km_bef == 1                                           , fe i(tincode) cluster(bhc tincode)
		  qui    areg  termall_km_exit     share211_1213_equity                                 `bank_controls'                  [aw = weight_bef]                    if f_km_loan_termall == 1  & termall_multi_km_bef == 1                                           , absorb(tincode) 
		  scalar r2_areg = e(r2)
		  scalar N_areg  = e(N)
		  estadd scalar r2_tot = r2_areg,   replace:    feexit2E
		  estadd scalar N_tot  = N_areg,    replace:    feexit2E
		  estadd local FE_bi  "Yes",        replace:    feexit2E
		  estadd local BC_bi  "Yes",        replace:    feexit2E
		  estadd local FE  "Firm",          replace:    feexit2E 		  		  		   
xtset tincode
eststo feexit4:   xtivreg2  termall_km_exit         share211_1213_committed   inter_size                   `bank_controls'                  [aw = weight_bef]                    if f_km_loan_termall == 1  & termall_multi_km_bef == 1                                           , fe i(tincode) cluster(bhc tincode)
		  qui  areg termall_km_exit         share211_1213_committed   inter_size                   `bank_controls'                  [aw = weight_bef]                    if f_km_loan_termall == 1  & termall_multi_km_bef == 1                                           , absorb(tincode) 
		  scalar r2_areg = e(r2)
		  scalar N_areg  = e(N)
		  estadd scalar r2_tot = r2_areg,   replace:    feexit4
		  estadd scalar N_tot  = N_areg,    replace:    feexit4
		  estadd local FE_bi  "Yes",        replace:    feexit4
		  estadd local BC_bi  "Yes",        replace:    feexit4
		  estadd local FE  "Firm",          replace:    feexit4
eststo feexit3:   xtivreg2  termall_km_exit         share211_1213_committed   `interallfe'                   `bank_controls'                  [aw = weight_bef]                    if f_km_loan_termall == 1  & termall_multi_km_bef == 1                                           , fe i(tincode) cluster(bhc tincode)
		  qui  areg termall_km_exit         share211_1213_committed   `interallfe'                   `bank_controls'                  [aw = weight_bef]                    if f_km_loan_termall == 1  & termall_multi_km_bef == 1                                           , absorb(tincode) 
		  scalar r2_areg = e(r2)
		  scalar N_areg  = e(N)
		  estadd scalar r2_tot = r2_areg,   replace:    feexit3
		  estadd scalar N_tot  = N_areg,    replace:    feexit3
		  estadd local FE_bi  "Yes",        replace:    feexit3
		  estadd local BC_bi  "Yes",        replace:    feexit3
		  estadd local FE  "Firm",          replace:    feexit3		   
	   drop fe_sample_dot
	   gen fe_sample_dot = e(sample)  
	   xtset zipind
eststo olsexit1:   xtivreg2  termall_km_exit         share211_1213_committed   `interallols'                  `bank_controls' `firm_controls'     [aw = weight_bef]                    if f_km_loan_termall == 1                                           & substr(ind3, 1,3) ~= "211" , fe i(zipind)    cluster(bhc zipind)
	          qui  areg  termall_km_exit         share211_1213_committed   `interallols'                  `bank_controls' `firm_controls'     [aw = weight_bef]                    if f_km_loan_termall == 1                                           & substr(ind3, 1,3) ~= "211" , absorb(zipind)    
		  scalar r2_areg = e(r2)
		  scalar N_areg  = e(N)
		  estadd scalar r2_tot = r2_areg,   replace:    olsexit1
		  estadd scalar N_tot  = N_areg,    replace:    olsexit1
		  estadd local BC_bi  "Yes",        replace:    olsexit1
		  estadd local FC_bi  "Yes",        replace:    olsexit1
		  estadd local FE  "Firm Controls", replace:    olsexit1
eststo olsexit1s:  xtivreg2  termall_km_exit         share211_1213_committed   `interallols'                 `bank_controls' `firm_controls'     [aw = weight_bef]                    if f_km_loan_termall == 1          & fe_sample_dot ==1             & substr(ind3, 1,3) ~= "211" , fe i(zipind)    cluster(bhc zipind)
		  qui  areg  termall_km_exit         share211_1213_committed   `interallols'                 `bank_controls' `firm_controls'     [aw = weight_bef]                    if f_km_loan_termall == 1          & fe_sample_dot ==1             & substr(ind3, 1,3) ~= "211" , absorb(zipind)   
		  scalar r2_areg = e(r2)
		  scalar N_areg  = e(N)
		  estadd scalar r2_tot = r2_areg,   replace:    olsexit1s
		   estadd scalar N_tot  = N_areg,   replace:    olsexit1s
		  estadd local BC_bi  "Yes",        replace:    olsexit1s
		  estadd local FC_bi  "Yes",        replace:    olsexit1s
		  estadd local FE  "Firm Controls", replace:    olsexit1s
eststo olsexit2:  xtivreg2  termall_km_exit         share211_1213_committed                                 `bank_controls' `firm_controls'     [aw = weight_bef]                    if f_km_loan_termall == 1                                           & substr(ind3, 1,3) ~= "211" , fe i(zipind)    cluster(bhc zipind)
	          qui  areg  termall_km_exit        share211_1213_committed                                 `bank_controls' `firm_controls'     [aw = weight_bef]                    if f_km_loan_termall == 1                                           & substr(ind3, 1,3) ~= "211" , absorb(zipind)   
		  scalar r2_areg = e(r2)
		  scalar N_areg  = e(N)
		  estadd scalar r2_tot = r2_areg,   replace:    olsexit2
		   estadd scalar N_tot  = N_areg,   replace:    olsexit2
		  estadd local BC_bi  "Yes",        replace:    olsexit2
		  estadd local FC_bi  "Yes",        replace:    olsexit2
		  estadd local FE  "Firm Controls", replace:    olsexit2
eststo olsexit2s: xtivreg2  termall_km_exit         share211_1213_committed                                 `bank_controls' `firm_controls'     [aw = weight_bef]                    if f_km_loan_termall == 1         & fe_sample_dot ==1              & substr(ind3, 1,3) ~= "211" , fe i(zipind)    cluster(bhc zipind)
		  qui  areg  termall_km_exit         share211_1213_committed                                `bank_controls' `firm_controls'     [aw = weight_bef]                    if f_km_loan_termall == 1         & fe_sample_dot ==1              & substr(ind3, 1,3) ~= "211" , absorb(zipind)   
		  scalar r2_areg = e(r2)
		  scalar N_areg  = e(N)
		  estadd scalar r2_tot = r2_areg,   replace:    olsexit2s
		  estadd scalar N_tot  = N_areg,    replace:    olsexit2s
		  estadd local BC_bi  "Yes",        replace:    olsexit2s
		  estadd local FC_bi  "Yes",        replace:    olsexit2s
		  estadd local FE  "Firm Controls", replace:    olsexit2s

eststo olsexit3:  xtivreg2  termall_km_exit         share211_1213_committed     `intersmall'                             `bank_controls' `firm_controls'     [aw = weight_bef]                    if f_km_loan_termall == 1                                           & substr(ind3, 1,3) ~= "211" , fe i(zipind)    cluster(bhc zipind)
	          qui  areg  termall_km_exit        share211_1213_committed     `intersmall'                             `bank_controls' `firm_controls'     [aw = weight_bef]                    if f_km_loan_termall == 1                                           & substr(ind3, 1,3) ~= "211" , absorb(zipind)   
		  scalar r2_areg = e(r2)
		  scalar N_areg  = e(N)
		  estadd scalar r2_tot = r2_areg,   replace:    olsexit3
		   estadd scalar N_tot  = N_areg,   replace:    olsexit3
		  estadd local BC_bi  "Yes",        replace:    olsexit3
		  estadd local FC_bi  "Yes",        replace:    olsexit3
		  estadd local FE  "Firm Controls", replace:    olsexit3


xtset tincode
eststo feentry1:  xtivreg2  termall_km_entry         share211_1213_committed                                                                                       if f_km_loan_termall == 1  & termall_multi_km_aft == 1                                           , fe i(tincode) cluster(bhc tincode)
		  qui  areg  termall_km_entry        share211_1213_committed                                                                                       if f_km_loan_termall == 1  & termall_multi_km_aft == 1                                           , absorb(tincode) 
	          scalar r2_areg = e(r2)
		  scalar N_areg  = e(N)
		  estadd scalar r2_tot = r2_areg,   replace:    feentry1
		  estadd scalar N_tot  = N_areg,    replace:    feentry1
		  estadd local FE_bi  "Yes",        replace:    feentry1
		  estadd local FE  "Firm",          replace:    feentry1 
eststo feentry2: xtivreg2  termall_km_entry        share211_1213_committed                                  `bank_controls'                                        if f_km_loan_termall == 1  & termall_multi_km_aft == 1                                           , fe i(tincode) cluster(bhc tincode)
		 qui  areg  termall_km_entry       share211_1213_committed                                  `bank_controls'                                        if f_km_loan_termall == 1  & termall_multi_km_aft == 1                                           , absorb(tincode)
		 scalar r2_areg = e(r2)
		 scalar N_areg  = e(N)
		 estadd scalar r2_tot = r2_areg,   replace:    feentry2
		 estadd scalar N_tot  = N_areg,    replace:    feentry2
		 estadd local FE_bi  "Yes",  	   replace:    feentry2
		 estadd local BC_bi  "Yes",  	   replace:    feentry2
		 estadd local FE  "Firm",          replace:    feentry2
           drop fe_sample_dot
	   gen fe_sample_dot = e(sample)  
	   bysort tincode: egen tin_exit    = max(termall_km_exit)
	   bysort tincode: egen tin_decline = max(d_km_l_loan_termall < 0)	   
eststo feentry5: xtivreg2  termall_km_entry         share211_1213_committed                                  `bank_controls'                                      if f_km_loan_termall == 1  & termall_multi_km_aft == 1       & tin_exit == 1                                    , fe i(tincode) cluster(bhc tincode)
	         qui  areg  termall_km_entry        share211_1213_committed                                  `bank_controls'                                      if f_km_loan_termall == 1  & termall_multi_km_aft == 1       & tin_exit == 1                                    , absorb(tincode)  
		 scalar r2_areg = e(r2)
		 scalar N_areg  = e(N)
		 estadd scalar r2_tot = r2_areg,   replace:    feentry5
		 estadd scalar N_tot  = N_areg,    replace:    feentry5
		 estadd local FE_bi  "Yes",        replace:    feentry5
	         estadd local BC_bi  "Yes",        replace:    feentry5
		 estadd local FE  "Firm",          replace:    feentry5 
eststo feentry6: xtivreg2  termall_km_entry         share211_1213_committed                                  `bank_controls'                                       if f_km_loan_termall == 1  & termall_multi_km_aft == 1       & tin_decline == 1                                    , fe i(tincode) cluster(bhc tincode)
		 qui  areg  termall_km_entry        share211_1213_committed                                  `bank_controls'                                       if f_km_loan_termall == 1  & termall_multi_km_aft == 1       & tin_decline == 1                                    , absorb(tincode)  
		 scalar r2_areg = e(r2)
		 scalar N_areg  = e(N)
		 estadd scalar r2_tot = r2_areg,   replace:    feentry6
		 estadd scalar N_tot  = N_areg,    replace:    feentry6
		 estadd local FE_bi  "Yes",        replace:    feentry6
		 estadd local BC_bi  "Yes",        replace:    feentry6
		 estadd local FE  "Firm",          replace:    feentry6 
eststo feentry7: xtivreg2  termall_km_entry         share211_1213_committed                                  `bank_controls'                                      if f_km_loan_termall == 1  & termall_multi_km_aft == 1       & tin_decline == 0                                    , fe i(tincode) cluster(bhc tincode)
		 qui  areg  termall_km_entry        share211_1213_committed                                  `bank_controls'                                      if f_km_loan_termall == 1  & termall_multi_km_aft == 1       & tin_decline == 0                                    , absorb(tincode)  
		 scalar r2_areg = e(r2)
		 scalar N_areg  = e(N)
		 estadd scalar r2_tot = r2_areg,   replace:    feentry7
		 estadd scalar N_tot  = N_areg,    replace:    feentry7
		 estadd local FE_bi  "Yes",        replace:    feentry7
		 estadd local BC_bi  "Yes",        replace:    feentry7
		 estadd local FE  "Firm",          replace:    feentry7 
eststo feentry8: xtivreg2  termall_km_entry         share211_1213_committed                                  `bank_controls'                                      if f_km_loan_termall == 1  & termall_multi_km_aft == 1       & tin_exit == 0                                    , fe i(tincode) cluster(bhc tincode)
                 qui areg  termall_km_entry         share211_1213_committed                                  `bank_controls'                                      if f_km_loan_termall == 1  & termall_multi_km_aft == 1       & tin_exit == 0                                    , absorb(tincode)  
		 scalar r2_areg = e(r2)
		 scalar N_areg  = e(N)
		 estadd scalar r2_tot = r2_areg,   replace:    feentry8
		 estadd scalar N_tot  = N_areg,    replace:    feentry8
		 estadd local FE_bi  "Yes",  	   replace:    feentry8
		 estadd local BC_bi  "Yes",        replace:    feentry8
		 estadd local FE  "Firm",          replace:    feentry8 
xtset zipind
eststo olsentry2: xtivreg2  termall_km_entry         share211_1213_committed                                  `bank_controls' `firm_controls'                         if f_km_loan_termall == 1                                           & substr(ind3, 1,3) ~= "211" , fe i(zipind)    cluster(bhc zipind)
                  qui areg  termall_km_entry         share211_1213_committed                                  `bank_controls' `firm_controls'                         if f_km_loan_termall == 1                                           & substr(ind3, 1,3) ~= "211" , absorb(zipind)     
		 scalar r2_areg = e(r2)
		 scalar N_areg  = e(N)
		 estadd scalar r2_tot = r2_areg,   replace:    olsentry2
		 estadd scalar N_tot  = N_areg,    replace:    olsentry2
		 estadd local BC_bi  "Yes",        replace:    olsentry2
	         estadd local FC_bi  "Yes",        replace:    olsentry2
		 estadd local FE  "Firm Controls", replace:    olsentry2
eststo olsentry2s:   xtivreg2  termall_km_entry         share211_1213_committed                                 `bank_controls' `firm_controls'                          if f_km_loan_termall == 1         & fe_sample_dot ==1              & substr(ind3, 1,3) ~= "211" , fe i(zipind)    cluster(bhc zipind)
	        qui    areg  termall_km_entry         share211_1213_committed                                 `bank_controls' `firm_controls'                            if f_km_loan_termall == 1         & fe_sample_dot ==1              & substr(ind3, 1,3) ~= "211" , absorb(zipind)    vce(cluster bhc)
		scalar r2_areg = e(r2)
		scalar N_areg  = e(N)
		estadd scalar r2_tot = r2_areg,   replace:    olsentry2s
		estadd scalar N_tot  = N_areg,    replace:    olsentry2s
	        estadd local BC_bi  "Yes",        replace:    olsentry2s
		estadd local FC_bi  "Yes",        replace:    olsentry2s
                estadd local FE  "Firm Controls", replace:    olsentry2s

*Aggregage (firm-Level) regressions
*local winsor_lhs .01
gen samp = .
replace samp = 1 if first_tin_dot == 1 & substr(ind3, 1,3) ~= "211" & ~missing(d_km_l_agg_termall)
gen term_samp = samp*d_km_l_agg_termall
gen util_samp = samp*d_km_l_agg_utilized
winsor term_samp, gen(wins1) p(`winsor_lhs')
winsor util_samp, gen(wins2) p(`winsor_lhs')
drop d_km_l_agg_termall d_km_l_agg_utilized term_samp util_samp
gen  d_km_l_agg_termall  = wins1
gen  d_km_l_agg_utilized = wins2
drop wins1 wins2
xtset zipind

eststo agg1:  reg  d_km_l_agg_termall exposure_agg_termall                                                                                                              `loan_controlsagg'                                    if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" ,                   robust
eststo agg2:  areg d_km_l_agg_termall exposure_agg_termall                                                                                                             `loan_controlsagg'  `bank_controlsagg' `firm_controls'   if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" , absorb(zipind)   robust
estadd local BC_bi  "Yes",  replace:    agg2
estadd local FC_bi  "Yes",  replace:    agg2
eststo agg3: areg d_km_l_agg_termall exposure_agg_termall inter_multi_agg multi_bank4                                                                                  `loan_controlsagg' `bank_controlsagg' `firm_controls'    if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" , absorb(zipind)   robust
estadd local BC_bi  "Yes",  replace:    agg3
estadd local FC_bi  "Yes",  replace:    agg3
eststo agg4: areg d_km_l_agg_termall exposure_agg_termall inter_multi_agg multi_bank4  inter_ext_agg ext     inter_open_agg  openlinepre     `loan_controlsagg' `bank_controlsagg' `firm_controls'   if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" , absorb(zipind)   robust
estadd local BC_bi  "Yes",  replace:    agg4
estadd local FC_bi  "Yes",  replace:    agg4
eststo agg5: areg d_km_l_agg_termall  exposure_agg_termall                             inter_ext_agg ext                                                            `loan_controlsagg' `bank_controlsagg' `firm_controls'   if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211"  , absorb(zipind)   robust
estadd local BC_bi  "Yes",  replace:    agg5
estadd local FC_bi  "Yes",  replace:    agg5 
eststo agg6: areg d_km_l_agg_termall  exposure_agg_termall                                                 inter_risky_agg risky_pre                                  `loan_controlsagg' `bank_controlsagg' `firm_controls'   if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211"  , absorb(zipind)   robust
estadd local BC_bi  "Yes",  replace:    agg6 
estadd local FC_bi  "Yes",  replace:    agg6 
eststo agg7: areg d_km_l_agg_termall  exposure_agg_termall                                                 inter_open_agg  openlinepre                                  `loan_controlsagg' `bank_controlsagg' `firm_controls'   if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211"  , absorb(zipind)    robust
estadd local BC_bi  "Yes",  replace:    agg7 
estadd local FC_bi  "Yes",  replace:    agg7
gen termall_samp = e(sample)
eststo agg8:  areg d_km_l_agg_termall exposure_agg_termall                                                                                                             `loan_controlsagg'  `bank_controlsagg' `firm_controls'   if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" & openlinepre == 1 , absorb(zipind)   robust
estadd local BC_bi  "Yes",  replace:    agg2
estadd local FC_bi  "Yes",  replace:    agg2




eststo agg1lc:  reg  d_km_l_agg_utilized exposure_agg_termall                                                                                                              `loan_controlsagg'                                    if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211"  & termall_samp == 1,                   robust
eststo agg2lc:  areg d_km_l_agg_utilized exposure_agg_termall                                                                                                             `loan_controlsagg'  `bank_controlsagg' `firm_controls'     if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211"  & termall_samp == 1, absorb(zipind)   robust
estadd local BC_bi  "Yes",  replace:    agg2lc
estadd local FC_bi  "Yes",  replace:    agg2lc
eststo agg3lc: areg d_km_l_agg_utilized exposure_agg_termall  inter_multi_agg multi_bank4                                                                                  `loan_controlsagg' `bank_controlsagg' `firm_controls'    if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" & termall_samp == 1, absorb(zipind)    robust
estadd local BC_bi  "Yes",  replace:    agg3lc
estadd local FC_bi  "Yes",  replace:    agg3lc
eststo agg4lc: areg d_km_l_agg_utilized exposure_agg_termall inter_multi_agg multi_bank4  inter_ext_agg ext   inter_open_agg  openlinepre         `loan_controlsagg' `bank_controlsagg' `firm_controls'   if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" & termall_samp == 1, absorb(zipind)    robust
estadd local BC_bi  "Yes",  replace:    agg4lc
estadd local FC_bi  "Yes",  replace:    agg4lc
eststo agg5lc: areg d_km_l_agg_utilized  exposure_agg_termall                            inter_ext_agg ext                                                                  `loan_controlsagg' `bank_controlsagg' `firm_controls'    if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" & termall_samp == 1 , absorb(zipind)    robust
estadd local BC_bi  "Yes",  replace:    agg5lc
estadd local FC_bi  "Yes",  replace:    agg5lc 
eststo agg6lc: areg d_km_l_agg_utilized  exposure_agg_termall                                                     inter_risky_agg risky_pre                                 `loan_controlsagg' `bank_controlsagg' `firm_controls'   if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" & termall_samp == 1 , absorb(zipind)    robust
estadd local BC_bi  "Yes",  replace:    agg6lc
estadd local FC_bi  "Yes",  replace:    agg6lc 
eststo agg7lc: areg d_km_l_agg_utilized  exposure_agg_termall                                                     inter_open_agg openlinepre                                 `loan_controlsagg' `bank_controlsagg' `firm_controls'   if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" & termall_samp == 1 , absorb(zipind)    robust
estadd local BC_bi  "Yes",  replace:    agg7lc
estadd local FC_bi  "Yes",  replace:    agg7lc 


replace agg_loan_aft_termall = 0 if missing(agg_loan_aft_termall) & tin_exit == 1
gen perc_change_agg =  (agg_loan_aft_termall - agg_loan_bef_termall)/agg_loan_bef_termall
areg perc_change_agg exposure_agg_termall                                                                                                             `loan_controlsagg'  `bank_controlsagg' `firm_controls'   if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" , absorb(zipind)   robust
bysort tincode: egen mean_exit = mean(termall_km_exit) 
gen agg_exit = mean_exit == 1 
areg agg_exit exposure_agg_termall                                                                                                             `loan_controlsagg'  `bank_controlsagg' `firm_controls'   if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" , absorb(zipind)   robust


*Switchers
	   bysort tincode: egen tin_entry    = max(termall_km_entry)
           gen switcher = tin_exit == 1 & tin_entry == 1
	   
eststo switch:  areg switcher exposure_agg_termall                                                                                                             `loan_controlsagg'  `bank_controlsagg' `firm_controls'   if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" , absorb(zipind)   robust
	       estadd local BC_bi  "Yes",  replace:   switch
               estadd local FC_bi  "Yes",  replace:   switch  
	       estadd local FE     "Firm Controls",          replace:    switch

	    
*Utilization Share

eststo share1: areg diff_ushare  exposure_agg_termall    `bank_controlsagg' `firm_controls'   if share_bef < 0.90   & first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" & termall_samp == 1 , absorb(zipind)     robust
estadd local BC_bi  "Yes",  replace:    share1
estadd local FC_bi  "Yes",  replace:    share1 
estadd local samp   "$<$ 0.90", replace:    share1
eststo share2: areg diff_ushare  exposure_agg_termall    `bank_controlsagg' `firm_controls'   if share_bef  < 0.75  & first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" & termall_samp == 1 , absorb(zipind)    robust
estadd local BC_bi  "Yes",  replace:    share2
estadd local FC_bi  "Yes",  replace:    share2 
estadd local samp   "$<$ 0.75", replace:   share2
eststo share3: areg diff_ushare exposure_agg_termall    `bank_controlsagg' `firm_controls'   if share_bef  < 0.50  & first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" & termall_samp == 1 , absorb(zipind)    robust
estadd local BC_bi  "Yes",  replace:    share3
estadd local FC_bi  "Yes",  replace:    share3 
estadd local samp   "$<$ 0.50", replace:   share3
eststo share4: areg diff_ushare  exposure_agg_termall inter_open_agg openlinepre    `bank_controlsagg' `firm_controls'   if share_bef < 1   & first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" & termall_samp == 1 , absorb(zipind)     robust
estadd local BC_bi  "Yes",  replace:    share1
estadd local FC_bi  "Yes",  replace:    share1 
eststo share5: areg diff_ushare  exposure_agg_termall                               `bank_controlsagg' `firm_controls'   if share_bef < 1   & first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" & termall_samp == 1 , absorb(zipind)     robust
estadd local BC_bi  "Yes",  replace:    share1
estadd local FC_bi  "Yes",  replace:    share1 



*Compustat
local varlist LIAB ASSETS EQUITY DIV CAPX EMP
foreach i of local varlist {
eststo comp_agg_`i': areg d_`i' exposure_agg_termall `firm_controls' `bank_controlsagg' if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" & termall_samp == 1  , absorb(zipind) robust
estadd local BC_bi  "Yes",  replace:    comp_agg_`i'
estadd local FC_bi  "Yes",  replace:    comp_agg_`i' 
eststo comp_agg_`i'2: areg d_`i' exposure_agg_termall inter_open_agg openlinepre     `firm_controls' `bank_controlsagg' if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" & termall_samp == 1  , absorb(zipind) robust
estadd local BC_bi  "Yes",  replace:    comp_agg_`i'2
estadd local FC_bi  "Yes",  replace:    comp_agg_`i'2 
eststo comp_agg_`i'3: areg d_`i' exposure_agg_termall inter_ext_agg ext      `firm_controls' `bank_controlsagg' if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" & termall_samp == 1  , absorb(zipind) robust
estadd local BC_bi  "Yes",  replace:    comp_agg_`i'3
estadd local FC_bi  "Yes",  replace:    comp_agg_`i'3 
eststo comp_agg_`i'4: areg d_`i' exposure_agg_termall inter_multi_agg multi_bank4      `firm_controls' `bank_controlsagg' if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" & termall_samp == 1  , absorb(zipind) robust
estadd local BC_bi  "Yes",  replace:    comp_agg_`i'4
estadd local FC_bi  "Yes",  replace:    comp_agg_`i'4
eststo comp_agg_`i'5: areg d_`i' exposure_agg_termall inter_multi_agg multi_bank4  inter_ext_agg ext   inter_open_agg  openlinepre       `firm_controls' `bank_controlsagg' if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" & termall_samp == 1  , absorb(zipind) robust
estadd local BC_bi  "Yes",  replace:    comp_agg_`i'5
estadd local FC_bi  "Yes",  replace:    comp_agg_`i'5
}  




log close
