/* BKS_oil_project_KM_regressions.do executes the regression analysis for the KM study. */

set	more off
cd	"/classified/l1jrk0b_l1rmb01/Output"
capture log close
log 	using BKS_oil_project_results, replace

 
*Choose Winsor Levels and Weights 
local winsor_lhs    .01   //Dependent variable winsor level
local winsor_weight .01   //Weight winsor level
local reg_weight   noweight //  Choose whether we are weighting the regessions: either noweight, winsorweight, oldweight


*Local controls
local bank_controls         ln_assets_mean roa_mean  foreign npl_share_comm_mean tier1rwa_share_mean ci_share_mean  loan_share_mean res_share_mean deposit_share_mean roe_mean co_share_mean
local bank_controlsagg      ln_assets_agg  roa_agg   foreign npl_share_comm_agg  tier1rwa_share_agg  ci_share_agg   loan_share_agg  res_share_agg  deposit_share_agg  roe_agg  co_share_agg


local bank_controlse        lag_logdeltaci  e_share ln_assets_mean roa_mean  foreign npl_share_comm_mean tier1rwa_share_mean ci_share_mean  loan_share_mean res_share_mean deposit_share_mean       co_share_mean

local loan_controls      avg_age_termall age2 age3  
local loan_controlsagg   avg_age_agg_termall ageagg2 ageagg3  
*local firm_controls     ext openlinepre risky_pre multi_bank4
local firm_controls      multi_bank
local intersmall         inter_size small_size 
local interrisky         inter_risky risky_pre 
local interext           inter_ext ext
local interold           inter_old old
local intermulti         inter_multib4 multi_bank4
local interallols        inter_ext ext inter_open  openlinepre    inter_multib4 multi_bank4   inter_old old
local interallfe         inter_ext     inter_open                              inter_multib4    inter_old old          

*Change to continuous

replace inter_open = share211_1213_committed*share_bef
replace openlinepre = share_bef
replace inter_multib4 = share211_1213_committed*numbankspre
replace multi_bank4 = numbankspre
replace old = maxlen
replace inter_old = share211_1213_committed*maxlen
replace	inter_multi_agg	        = exposure_agg_termall*numbankspre
replace inter_open_agg          = exposure_agg_termall*share_bef


*Change multi bank
*replace multi_bank = numbankspre > 1
*replace multi_bank4 = multi_bank
*replace inter_multib4 = share211_1213_committed*multi_bank
*replace	inter_multi_agg	        = exposure_agg_termall*multi_bank
 
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
winsor assets if first_tin_dot == 1, gen(assets_win) p(0.05)
bysort tincode: egen assets_winm = max(assets_win)

areg d_km_l_loan_termall   share211_1213_committed    `loan_controls' `bank_controls'    if f_km_loan_termall == 1  & termall_multi_km  == 1      & balance == 1                                        , absorb(tincode) 
gen int_fe  = e(sample)
areg d_km_l_loan_termall     share211_1213_committed                  `loan_controls' `bank_controls' `firm_controls'  if f_km_loan_termall == 1                                            & substr(ind3, 1,3) ~= "211" & balance == 1, absorb(zipind)  
gen int_ols = e(sample)
areg  termall_km_exit         share211_1213_committed                                  `bank_controls'                           if f_km_loan_termall == 1  & termall_multi_km_bef == 1                                           , absorb(tincode) 
gen ex_fe  =  e(sample)
areg  termall_km_exit         share211_1213_committed                                  `bank_controls' `firm_controls'                        if f_km_loan_termall == 1                                           & substr(ind3, 1,3) ~= "211" , absorb(zipind)    
gen ex_ols = e(sample)
areg  termall_km_entry         share211_1213_committed                                  `bank_controls'                                  if f_km_loan_termall == 1  & termall_multi_km_aft == 1                                           , absorb(tincode) 
gen ent_fe = e(sample)
areg  termall_km_entry         share211_1213_committed                                  `bank_controls' `firm_controls'                        if f_km_loan_termall == 1                                           & substr(ind3, 1,3) ~= "211" , absorb(zipind)    
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

sum assets_winm ext numbankspre share_bef if int_fe == 1  & int_tin_fe == 1
sum assets_winm ext numbankspre share_bef if int_ols == 1 & int_tin_ols == 1
sum assets_winm ext numbankspre share_bef if ex_fe == 1  & ex_tin_fe == 1
sum assets_winm ext numbankspre share_bef if ex_ols == 1 & ex_tin_ols == 1
sum assets_winm ext numbankspre share_bef if ent_fe == 1  & ent_tin_fe == 1
sum assets_winm ext numbankspre share_bef if ent_ols == 1 & ent_tin_ols == 1

sum d_km_l_loan_termall termall_km_exit termall_km_entry old km_loan_bef_termall   if int_fe == 1 
sum d_km_l_loan_termall termall_km_exit termall_km_entry old km_loan_bef_termall   if int_ols == 1 
sum d_km_l_loan_termall termall_km_exit termall_km_entry old km_loan_bef_termall   if ex_fe == 1 
sum d_km_l_loan_termall termall_km_exit termall_km_entry old km_loan_bef_termall   if ex_ols == 1 
sum d_km_l_loan_termall termall_km_exit termall_km_entry old  if ent_fe == 1 
sum d_km_l_loan_termall termall_km_exit termall_km_entry old  if ent_ols == 1 

**Variance correction for bias corrections**
areg d_km_l_agg_termall exposure_agg_termall `loan_controlsagg'  `bank_controlsagg' `firm_controls'   if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" , absorb(zipind)   vce(robust)
sum exposure_agg_termall if e(sample)
sum share211_1213_committed if int_fe 
sum share211_1213_committed if int_ols 


*KM Regressions
eststo feintens1:  areg d_km_l_loan_termall     share211_1213_committed                 `loan_controls'                                  [aw = weight_bef]  if f_km_loan_termall == 1  & termall_multi_km  == 1      & balance == 1                                        , absorb(tincode) vce(cluster bhc)
estadd local FE  "Firm",  replace:    feintens1
eststo feintens2:  areg d_km_l_loan_termall     share211_1213_committed                 `loan_controls' `bank_controls'                  [aw = weight_bef]  if f_km_loan_termall == 1  & termall_multi_km  == 1      & balance == 1                                        , absorb(tincode) vce(cluster bhc)
estadd local FE  "Firm",  replace:    feintens2
eststo feintens3:  areg d_km_l_loan_termall     share211_1213_committed   inter_multib4  `loan_controls' `bank_controls'                 [aw = weight_bef]  if f_km_loan_termall == 1  & termall_multi_km  == 1      & balance == 1                                        , absorb(tincode) vce(cluster bhc)
estadd local FE  "Firm",  replace:    feintens3
eststo feintens4:  areg d_km_l_loan_termall     share211_1213_committed   inter_risky   `loan_controls' `bank_controls'                  [aw = weight_bef]  if f_km_loan_termall == 1  & termall_multi_km  == 1      & balance == 1                                        , absorb(tincode) vce(cluster bhc)
estadd local FE  "Firm",  replace:    feintens4
eststo feintens5:  areg d_km_l_loan_termall     share211_1213_committed   inter_ext    `loan_controls' `bank_controls'                   [aw = weight_bef]  if f_km_loan_termall == 1  & termall_multi_km  == 1         & balance == 1                                     , absorb(tincode) vce(cluster bhc)
estadd local FE  "Firm",  replace:    feintens5
eststo feintens6:  areg d_km_l_loan_termall     share211_1213_committed   `interold'    `loan_controls' `bank_controls'                  [aw = weight_bef]  if f_km_loan_termall == 1  & termall_multi_km  == 1      & balance == 1                                        , absorb(tincode) vce(cluster bhc)
estadd local FE  "Firm",  replace:    feintens6             		   		    
eststo feintens7:  areg d_km_l_loan_termall     share211_1213_committed  `interallfe'   `loan_controls' `bank_controls'                  [aw = weight_bef]  if f_km_loan_termall == 1  & termall_multi_km  == 1      & balance == 1                                        , absorb(tincode) vce(cluster bhc)
estadd local FE  "Firm",  replace:    feintens7
eststo feintens8:  areg d_km_l_loan_termall     share211_1213_committed   inter_open   `loan_controls' `bank_controls'                   [aw = weight_bef]  if f_km_loan_termall == 1  & termall_multi_km  == 1       & balance == 1                                       , absorb(tincode) vce(cluster bhc)
estadd local FE  "Firm",  replace:    feintens8                
			 gen fe_sample_dot = e(sample)           
eststo olsintens1:  reg d_km_l_loan_termall     share211_1213_committed                  `loan_controls'                                 [aw = weight_bef]  if f_km_loan_termall == 1  & termall_multi_km  == 1 & fe_sample_dot ==1 & substr(ind3, 1,3) ~= "211"  & balance == 1,                 vce(cluster bhc)
eststo olsintens2:  reg d_km_l_loan_termall     share211_1213_committed                  `loan_controls'                                 [aw = weight_bef]  if f_km_loan_termall == 1                                           & substr(ind3, 1,3) ~= "211"  & balance == 1,                 vce(cluster bhc)
eststo olsintens3:  reg d_km_l_loan_termall     share211_1213_committed                  `loan_controls' `bank_controls'                 [aw = weight_bef]  if f_km_loan_termall == 1                                           & substr(ind3, 1,3) ~= "211" & balance == 1,                 vce(cluster bhc)
eststo olsintens3s: reg d_km_l_loan_termall     share211_1213_committed                  `loan_controls' `bank_controls'                 [aw = weight_bef]  if f_km_loan_termall == 1  & termall_multi_km  == 1 & fe_sample_dot ==1 & substr(ind3, 1,3) ~= "211" & balance == 1,                 vce(cluster bhc)
eststo olsintens4:  reg d_km_l_loan_termall     share211_1213_committed   `intersmall'   `loan_controls'                                 [aw = weight_bef]  if f_km_loan_termall == 1                                           & substr(ind3, 1,3) ~= "211" & balance == 1 ,                 vce(cluster bhc)
eststo olsintens4s: reg d_km_l_loan_termall     share211_1213_committed   `intersmall'   `loan_controls'                                 [aw = weight_bef]  if f_km_loan_termall == 1  & termall_multi_km  == 1 & fe_sample_dot ==1 & substr(ind3, 1,3) ~= "211" & balance == 1,                 vce(cluster bhc)
eststo olsintens5: areg d_km_l_loan_termall     share211_1213_committed   `intersmall'   `loan_controls' `bank_controls' `firm_controls' [aw = weight_bef]  if f_km_loan_termall == 1                                            & substr(ind3, 1,3) ~= "211" & balance == 1, absorb(zipind)  vce(cluster bhc)
estadd local FE  "Firm Controls",  replace:     olsintens5
eststo olsintens5s: areg d_km_l_loan_termall    share211_1213_committed   `intersmall'   `loan_controls' `bank_controls' `firm_controls' [aw = weight_bef]  if f_km_loan_termall == 1 & termall_multi_km  == 1 & fe_sample_dot ==1  & substr(ind3, 1,3) ~= "211" & balance == 1, absorb(zipind)  vce(cluster bhc)
estadd local FE  "Firm Controls",  replace:     olsintens5s
eststo olsintens6: areg d_km_l_loan_termall     share211_1213_committed   `interallols'  `loan_controls' `bank_controls' `firm_controls' [aw = weight_bef]  if f_km_loan_termall == 1                                            & substr(ind3, 1,3) ~= "211" & balance == 1 , absorb(zipind)  vce(cluster bhc)
estadd local FE  "Firm Controls",  replace:     olsintens6
eststo olsintens6s: areg d_km_l_loan_termall    share211_1213_committed   `interallols'  `loan_controls' `bank_controls' `firm_controls' [aw = weight_bef]  if f_km_loan_termall == 1 & termall_multi_km  == 1 & fe_sample_dot ==1  & substr(ind3, 1,3) ~= "211" & balance== 1 , absorb(zipind)  vce(cluster bhc)
estadd local FE  "Firm Controls",  replace:     olsintens6s
eststo olsintens7: areg d_km_l_loan_termall     share211_1213_committed   `interrisky'  `loan_controls' `bank_controls' `firm_controls'  [aw = weight_bef]  if f_km_loan_termall == 1                                            & substr(ind3, 1,3) ~= "211" & balance == 1, absorb(zipind)  vce(cluster bhc)
estadd local FE  "Firm Controls",  replace:     olsintens7
eststo olsintens8: areg d_km_l_loan_termall     share211_1213_committed   `interold'  `loan_controls' `bank_controls' `firm_controls'     [aw = weight_bef]  if f_km_loan_termall == 1                                            & substr(ind3, 1,3) ~= "211" & balance == 1 , absorb(zipind)  vce(cluster bhc)
estadd local FE  "Firm Controls",  replace:     olsintens8
eststo olsintens9: areg d_km_l_loan_termall     share211_1213_committed   `interext'  `loan_controls' `bank_controls' `firm_controls'  [aw = weight_bef]  if f_km_loan_termall == 1                                            & substr(ind3, 1,3) ~= "211" & balance == 1 , absorb(zipind)  vce(cluster bhc)
estadd local FE  "Firm Controls",  replace:     olsintens9
eststo olsintens10: areg d_km_l_loan_termall     share211_1213_committed                  `loan_controls' `bank_controls' `firm_controls' [aw = weight_bef]  if f_km_loan_termall == 1                                            & substr(ind3, 1,3) ~= "211" & balance == 1, absorb(zipind)  vce(cluster bhc)
estadd local FE  "Firm Controls",  replace:     olsintens10
eststo olsintens10s: areg d_km_l_loan_termall     share211_1213_committed                  `loan_controls' `bank_controls' `firm_controls' [aw = weight_bef]  if f_km_loan_termall == 1                       & fe_sample_dot ==1 & substr(ind3, 1,3) ~= "211" & balance == 1 , absorb(zipind)  vce(cluster bhc)
estadd local FE  "Firm Controls",  replace:     olsintens10s
eststo olsintens11: areg d_km_l_loan_termall     share211_1213_committed   `intermulti'  `loan_controls' `bank_controls' `firm_controls'  [aw = weight_bef]  if f_km_loan_termall == 1                                            & substr(ind3, 1,3) ~= "211" & balance == 1 , absorb(zipind)  vce(cluster bhc)
estadd local FE  "Firm Controls",  replace:     olsintens11
eststo olsintens12: areg d_km_l_loan_termall     share211_1213_committed   inter_open  openlinepre  `loan_controls' `bank_controls' `firm_controls'  [aw = weight_bef]  if f_km_loan_termall == 1                                            & substr(ind3, 1,3) ~= "211" & balance == 1 , absorb(zipind)  vce(cluster bhc)
estadd local FE  "Firm Controls",  replace:     olsintens12

eststo feexit1:   areg  termall_km_exit         share211_1213_committed                                                                   [aw = weight_bef]                    if f_km_loan_termall == 1  & termall_multi_km_bef == 1                                           , absorb(tincode) vce(cluster bhc)
estadd local FE_bi  "Yes",  replace:    feexit1
eststo feexit2:   areg  termall_km_exit         share211_1213_committed                                  `bank_controls'                  [aw = weight_bef]                    if f_km_loan_termall == 1  & termall_multi_km_bef == 1                                           , absorb(tincode) vce(cluster bhc)
estadd local FE_bi  "Yes",  replace:    feexit2
estadd local BC_bi  "Yes",  replace:    feexit2
eststo feexit3:   areg  termall_km_exit         share211_1213_committed   `interallfe'                   `bank_controls'                  [aw = weight_bef]                    if f_km_loan_termall == 1  & termall_multi_km_bef == 1                                           , absorb(tincode) vce(cluster bhc)
estadd local FE_bi  "Yes",  replace:    feexit3
estadd local BC_bi  "Yes",  replace:    feexit3
eststo feexit4:   areg  termall_km_exit         share211_1213_committed    inter_ext                  `bank_controls'                  [aw = weight_bef]                    if f_km_loan_termall == 1  & termall_multi_km_bef == 1                                           , absorb(tincode) vce(cluster bhc)
estadd local FE_bi  "Yes",  replace:    feexit4
estadd local BC_bi  "Yes",  replace:    feexit4
eststo feexit5:   areg  termall_km_exit         share211_1213_committed    `interold'                 `bank_controls'                  [aw = weight_bef]                    if f_km_loan_termall == 1  & termall_multi_km_bef == 1                                           , absorb(tincode) vce(cluster bhc)
estadd local FE_bi  "Yes",  replace:    feexit5
estadd local BC_bi  "Yes",  replace:    feexit5
eststo feexit6:   areg  termall_km_exit         share211_1213_committed    inter_risky                 `bank_controls'                  [aw = weight_bef]                    if f_km_loan_termall == 1  & termall_multi_km_bef == 1                                           , absorb(tincode) vce(cluster bhc)
estadd local FE_bi  "Yes",  replace:    feexit6
estadd local BC_bi  "Yes",  replace:    feexit6
eststo feexit7:   areg  termall_km_exit         share211_1213_committed    inter_multib4                `bank_controls'                     [aw = weight_bef]                    if f_km_loan_termall == 1  & termall_multi_km_bef == 1                                           , absorb(tincode) vce(cluster bhc)
estadd local FE_bi  "Yes",  replace:    feexit7
estadd local BC_bi  "Yes",  replace:    feexit7
eststo feexit8:   areg  termall_km_exit         share211_1213_committed    inter_open                `bank_controls'                     [aw = weight_bef]                    if f_km_loan_termall == 1  & termall_multi_km_bef == 1                                           , absorb(tincode) vce(cluster bhc)
estadd local FE_bi  "Yes",  replace:    feexit8
estadd local BC_bi  "Yes",  replace:    feexit8
           drop fe_sample_dot
	   gen fe_sample_dot = e(sample)  
eststo olsexit1:   areg  termall_km_exit         share211_1213_committed   `interallols'                  `bank_controls' `firm_controls'     [aw = weight_bef]                    if f_km_loan_termall == 1                                           & substr(ind3, 1,3) ~= "211" , absorb(zipind)    vce(cluster bhc)
estadd local BC_bi  "Yes",  replace:    olsexit1
estadd local FC_bi  "Yes",  replace:    olsexit1
eststo olsexit1s:   areg  termall_km_exit         share211_1213_committed   `interallols'                 `bank_controls' `firm_controls'     [aw = weight_bef]                    if f_km_loan_termall == 1          & fe_sample_dot ==1             & substr(ind3, 1,3) ~= "211" , absorb(zipind)    vce(cluster bhc)
estadd local BC_bi  "Yes",  replace:    olsexit1s
estadd local FC_bi  "Yes",  replace:    olsexit1s
eststo olsexit2:   areg  termall_km_exit         share211_1213_committed                                  `bank_controls' `firm_controls'     [aw = weight_bef]                    if f_km_loan_termall == 1                                           & substr(ind3, 1,3) ~= "211" , absorb(zipind)    vce(cluster bhc)
estadd local BC_bi  "Yes",  replace:    olsexit2
estadd local FC_bi  "Yes",  replace:    olsexit2
eststo olsexit2s:   areg  termall_km_exit         share211_1213_committed                                 `bank_controls' `firm_controls'     [aw = weight_bef]                    if f_km_loan_termall == 1         & fe_sample_dot ==1              & substr(ind3, 1,3) ~= "211" , absorb(zipind)    vce(cluster bhc)
estadd local BC_bi  "Yes",  replace:    olsexit2s
estadd local FC_bi  "Yes",  replace:    olsexit2s

eststo feentry1:   areg  termall_km_entry         share211_1213_committed                                                                   [aw = weight_aft]                    if f_km_loan_termall == 1  & termall_multi_km_aft == 1                                           , absorb(tincode) vce(cluster bhc)
estadd local FE_bi  "Yes",  replace:    feentry1
eststo feentry2:   areg  termall_km_entry         share211_1213_committed                                  `bank_controls'                  [aw = weight_aft]                    if f_km_loan_termall == 1  & termall_multi_km_aft == 1                                           , absorb(tincode) vce(cluster bhc)
estadd local FE_bi  "Yes",  replace:    feentry2
estadd local BC_bi  "Yes",  replace:    feentry2
eststo feentry4:   areg  termall_km_entry         share211_1213_committed    inter_ext                  `bank_controls'                  [aw = weight_aft]                    if f_km_loan_termall == 1  & termall_multi_km_aft == 1                                           , absorb(tincode) vce(cluster bhc)
estadd local FE_bi  "Yes",  replace:    feentry4
estadd local BC_bi  "Yes",  replace:    feentry4
           drop fe_sample_dot
	   gen fe_sample_dot = e(sample)  
bysort tincode: egen tin_exit = max(termall_km_exit)
bysort tincode: egen tin_decline = max(d_km_l_loan_termall < 0)	   
eststo feentry5:   areg  termall_km_entry         share211_1213_committed                                  `bank_controls'                  [aw = weight_aft]                    if f_km_loan_termall == 1  & termall_multi_km_aft == 1       & tin_exit == 1                                    , absorb(tincode) vce(cluster bhc)
estadd local FE_bi  "Yes",  replace:    feentry5
estadd local BC_bi  "Yes",  replace:    feentry5
eststo feentry6:   areg  termall_km_entry         share211_1213_committed                                  `bank_controls'                  [aw = weight_aft]                    if f_km_loan_termall == 1  & termall_multi_km_aft == 1       & tin_decline == 1                                    , absorb(tincode) vce(cluster bhc)
estadd local FE_bi  "Yes",  replace:    feentry6
estadd local BC_bi  "Yes",  replace:    feentry6
eststo feentry7:   areg  termall_km_entry         share211_1213_committed                                  `bank_controls'                  [aw = weight_aft]                    if f_km_loan_termall == 1  & termall_multi_km_aft == 1       & tin_decline == 0                                    , absorb(tincode) vce(cluster bhc)
estadd local FE_bi  "Yes",  replace:    feentry7
estadd local BC_bi  "Yes",  replace:    feentry7
eststo feentry8:   areg  termall_km_entry         share211_1213_committed                                  `bank_controls'                  [aw = weight_aft]                    if f_km_loan_termall == 1  & termall_multi_km_aft == 1       & tin_exit == 0                                    , absorb(tincode) vce(cluster bhc)
estadd local FE_bi  "Yes",  replace:    feentry8
estadd local BC_bi  "Yes",  replace:    feentry8
eststo olsentry2:   areg  termall_km_entry         share211_1213_committed                                  `bank_controls' `firm_controls'     [aw = weight_aft]                    if f_km_loan_termall == 1                                           & substr(ind3, 1,3) ~= "211" , absorb(zipind)    vce(cluster bhc)
estadd local BC_bi  "Yes",  replace:    olsentry2
estadd local FC_bi  "Yes",  replace:    olsentry2
eststo olsentry2s:   areg  termall_km_entry         share211_1213_committed                                 `bank_controls' `firm_controls'     [aw = weight_aft]                    if f_km_loan_termall == 1         & fe_sample_dot ==1              & substr(ind3, 1,3) ~= "211" , absorb(zipind)    vce(cluster bhc)
estadd local BC_bi  "Yes",  replace:    olsentry2s
estadd local FC_bi  "Yes",  replace:    olsentry2s




*Aggregage (firm-Level) regressions

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


eststo agg1:  reg  d_km_l_agg_termall exposure_agg_termall                                                                                                              `loan_controlsagg'                                    if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" ,                   vce(robust)
eststo agg2:  areg d_km_l_agg_termall exposure_agg_termall                                                                                                             `loan_controlsagg'  `bank_controlsagg' `firm_controls'   if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" , absorb(zipind)   vce(robust)
estadd local BC_bi  "Yes",  replace:    agg2
estadd local FC_bi  "Yes",  replace:    agg2
eststo agg3: areg d_km_l_agg_termall exposure_agg_termall inter_multi_agg multi_bank4                                                                                  `loan_controlsagg' `bank_controlsagg' `firm_controls'    if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" , absorb(zipind)    vce(robust)
estadd local BC_bi  "Yes",  replace:    agg3
estadd local FC_bi  "Yes",  replace:    agg3
eststo agg4: areg d_km_l_agg_termall exposure_agg_termall inter_multi_agg multi_bank4  inter_ext_agg ext     inter_open_agg  openlinepre     `loan_controlsagg' `bank_controlsagg' `firm_controls'   if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" , absorb(zipind)    vce(robust)
estadd local BC_bi  "Yes",  replace:    agg4
estadd local FC_bi  "Yes",  replace:    agg4
eststo agg5: areg d_km_l_agg_termall  exposure_agg_termall                             inter_ext_agg ext                                                            `loan_controlsagg' `bank_controlsagg' `firm_controls'   if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211"  , absorb(zipind)    vce(robust)
estadd local BC_bi  "Yes",  replace:    agg5
estadd local FC_bi  "Yes",  replace:    agg5 
eststo agg6: areg d_km_l_agg_termall  exposure_agg_termall                                                 inter_risky_agg risky_pre                                  `loan_controlsagg' `bank_controlsagg' `firm_controls'   if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211"  , absorb(zipind)    vce(robust)
estadd local BC_bi  "Yes",  replace:    agg6 
estadd local FC_bi  "Yes",  replace:    agg6 
eststo agg7: areg d_km_l_agg_termall  exposure_agg_termall                                                 inter_open_agg  openlinepre                                  `loan_controlsagg' `bank_controlsagg' `firm_controls'   if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211"  , absorb(zipind)    vce(robust)
estadd local BC_bi  "Yes",  replace:    agg7 
estadd local FC_bi  "Yes",  replace:    agg7
gen termall_samp = e(sample)

eststo agg8:  areg d_km_l_agg_termall exposure_agg_termall                                                                                                             `loan_controlsagg'  `bank_controlsagg' `firm_controls'   if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" & openlinepre == 1 , absorb(zipind)   vce(robust)
estadd local BC_bi  "Yes",  replace:    agg2
estadd local FC_bi  "Yes",  replace:    agg2




eststo agg1lc:  reg  d_km_l_agg_utilized exposure_agg_termall                                                                                                              `loan_controlsagg'                                    if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211"  & termall_samp == 1,                   vce(robust)
eststo agg2lc:  areg d_km_l_agg_utilized exposure_agg_termall                                                                                                             `loan_controlsagg'  `bank_controlsagg' `firm_controls'     if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211"  & termall_samp == 1, absorb(zipind)   vce(robust)
estadd local BC_bi  "Yes",  replace:    agg2lc
estadd local FC_bi  "Yes",  replace:    agg2lc
eststo agg3lc: areg d_km_l_agg_utilized exposure_agg_termall  inter_multi_agg multi_bank4                                                                                  `loan_controlsagg' `bank_controlsagg' `firm_controls'    if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" & termall_samp == 1, absorb(zipind)    vce(robust)
estadd local BC_bi  "Yes",  replace:    agg3lc
estadd local FC_bi  "Yes",  replace:    agg3lc
eststo agg4lc: areg d_km_l_agg_utilized exposure_agg_termall inter_multi_agg multi_bank4  inter_ext_agg ext   inter_open_agg  openlinepre         `loan_controlsagg' `bank_controlsagg' `firm_controls'   if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" & termall_samp == 1, absorb(zipind)    vce(robust)
estadd local BC_bi  "Yes",  replace:    agg4lc
estadd local FC_bi  "Yes",  replace:    agg4lc
eststo agg5lc: areg d_km_l_agg_utilized  exposure_agg_termall                            inter_ext_agg ext                                                                  `loan_controlsagg' `bank_controlsagg' `firm_controls'    if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" & termall_samp == 1 , absorb(zipind)    vce(robust)
estadd local BC_bi  "Yes",  replace:    agg5lc
estadd local FC_bi  "Yes",  replace:    agg5lc 
eststo agg6lc: areg d_km_l_agg_utilized  exposure_agg_termall                                                     inter_risky_agg risky_pre                                 `loan_controlsagg' `bank_controlsagg' `firm_controls'   if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" & termall_samp == 1 , absorb(zipind)    vce(robust)
estadd local BC_bi  "Yes",  replace:    agg6lc
estadd local FC_bi  "Yes",  replace:    agg6lc 
eststo agg7lc: areg d_km_l_agg_utilized  exposure_agg_termall                                                     inter_open_agg openlinepre                                 `loan_controlsagg' `bank_controlsagg' `firm_controls'   if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" & termall_samp == 1 , absorb(zipind)    vce(robust)
estadd local BC_bi  "Yes",  replace:    agg7lc
estadd local FC_bi  "Yes",  replace:    agg7lc 


*Utilization Share

eststo share1: areg diff_ushare  exposure_agg_termall    `bank_controlsagg' `firm_controls'   if share_bef < 0.90   & first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" & termall_samp == 1 , absorb(zipind)    vce(robust)
estadd local BC_bi  "Yes",  replace:    share1
estadd local FC_bi  "Yes",  replace:    share1 
estadd local samp   "$<$ 0.90", replace:    share1
eststo share2: areg diff_ushare  exposure_agg_termall    `bank_controlsagg' `firm_controls'   if share_bef  < 0.75  & first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" & termall_samp == 1 , absorb(zipind)    vce(robust)
estadd local BC_bi  "Yes",  replace:    share2
estadd local FC_bi  "Yes",  replace:    share2 
estadd local samp   "$<$ 0.75", replace:   share2
eststo share3: areg diff_ushare  exposure_agg_termall    `bank_controlsagg' `firm_controls'   if share_bef  < 0.50  & first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" & termall_samp == 1 , absorb(zipind)    vce(robust)
estadd local BC_bi  "Yes",  replace:    share3
estadd local FC_bi  "Yes",  replace:    share3 
estadd local samp   "$<$ 0.50", replace:   share3

*Compustat
local varlist LIAB ASSETS EQUITY DIV CAPX EMP
foreach i of local varlist {
eststo comp_agg_`i': reg d_`i' exposure_agg_termall `firm_controls' `bank_controlsagg' if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" & termall_samp == 1  , vce(robust)
estadd local BC_bi  "Yes",  replace:    comp_agg_`i'
estadd local FC_bi  "Yes",  replace:    comp_agg_`i' 
eststo comp_agg_`i'2: reg d_`i' exposure_agg_termall inter_open_agg openlinepre     `firm_controls' `bank_controlsagg' if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" & termall_samp == 1  , vce(robust)
estadd local BC_bi  "Yes",  replace:    comp_agg_`i'2
estadd local FC_bi  "Yes",  replace:    comp_agg_`i'2 
eststo comp_agg_`i'3: reg d_`i' exposure_agg_termall inter_ext_agg ext      `firm_controls' `bank_controlsagg' if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" & termall_samp == 1  , vce(robust)
estadd local BC_bi  "Yes",  replace:    comp_agg_`i'3
estadd local FC_bi  "Yes",  replace:    comp_agg_`i'3 
eststo comp_agg_`i'4: reg d_`i' exposure_agg_termall inter_multi_agg multi_bank4      `firm_controls' `bank_controlsagg' if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" & termall_samp == 1  , vce(robust)
estadd local BC_bi  "Yes",  replace:    comp_agg_`i'4
estadd local FC_bi  "Yes",  replace:    comp_agg_`i'4
eststo comp_agg_`i'5: reg d_`i' exposure_agg_termall inter_multi_agg multi_bank4  inter_ext_agg ext   inter_open_agg  openlinepre       `firm_controls' `bank_controlsagg' if first_tin_dot == 1   & substr(ind3, 1,3) ~= "211" & termall_samp == 1  , vce(robust)
estadd local BC_bi  "Yes",  replace:    comp_agg_`i'5
estadd local FC_bi  "Yes",  replace:    comp_agg_`i'5
}  




log close
