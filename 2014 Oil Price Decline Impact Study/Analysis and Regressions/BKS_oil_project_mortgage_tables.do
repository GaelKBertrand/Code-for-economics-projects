cd "/mnt/lan-shared/Adam/BidderKrainerShapiro/Tables"
local varlist tot toto port porto pgov pgovo portj portjo portnj portnjo nport nportgse nporto 
local bank_controls  lag_logdeltares lag_logdeltambs  ln_assets_mean roa_mean foreign npl_share_comm_mean tier1rwa_share_mean ci_share_mean loan_share_mean res_share_mean deposit_share_mean e_share co_share_mean 
local county_controls lnpop lndens percvet lnhdens percenturbanhousingunits percocchousunits percvac lnhvalue lnrent frac3plus personsinpoverty disabled1864civilnoninstl unemploymentrate16 lnhhi
local bank_controls_agg  lag_logdeltares_agg lag_logdeltambs_agg  ln_assets_mean_agg roa_mean_agg foreign_agg npl_share_comm_mean_agg tier1rwa_share_mean_agg ci_share_mean_agg loan_share_mean_agg res_share_mean_agg deposit_share_mean_agg e_share co_share_mean_agg 






#delimit;
estout  agg1 agg2 agg3  agg4 using aggOLS.tex, 
mlabels("Port-Orig" "Port" "Tot Y14" "Tot LPS")
replace cells(b(star fmt(%9.3f)) se(par fmt(3)))
starlevels(* 0.10 ** 0.05 *** 0.01)
style(tex) 
stats(N r2 BC FE CC, fmt(0 2) labels("Number of Observations" "R-squared" "Bank Controls" "Fixed Effects" "County Controls" ))
collabels(none) 
drop(`bank_controls_agg' `county_controls'  *.st_code _cons)
order(exposure_county )
varlabel(exposure_county "Aggregate O\&G Exposure" );
#delimit cr


#delimit;
estout  fe_port  fe_portj fe_portnj  fe_nport fe_nportnj fe_gov fe_tot using non_origFE.tex, 
mlabels( "Port"  "\shortstack{Port\\Jumbo}" "\shortstack{Port\\Non-Jumbo}"  "Non-Port" "Non-Port Non-Jumbo" "Gov" "All") 
replace cells(b(star fmt(%9.3f)) se(par fmt(3)))
starlevels(* 0.10 ** 0.05 *** 0.01)
style(tex) 
stats(N_tot r2_tot BC FE CC, fmt(0 2) labels("Number of Observations" "R-squared" "Bank Controls" "Fixed Effects" "County Controls" ))
collabels(none) 
drop(`bank_controls' )
order(share211_1213_committed )
varlabel(share211_1213_committed "O\&G Exposure" );
#delimit cr


#delimit;
estout    fe_porto fe_portjo fe_portnjo  fe_nporto   fe_nportnjo fe_govo fe_toto  using origFE.tex, 
mlabels("Port" "\shortstack{Port\\Jumbo}" "\shortstack{Port\\Non-Jumbo}" "Gov" "Non-Port" "Non-Port Non-Jumbo" "All"   ) 
replace cells(b(star fmt(%9.3f)) se(par fmt(3)))
starlevels(* 0.10 ** 0.05 *** 0.01)
style(tex) 
stats(N_tot r2_tot BC FE CC, fmt(0 2) labels("Number of Observations" "R-squared" "Bank Controls" "Fixed Effects" "County Controls" ))
collabels(none) 
drop(`bank_controls')
order(share211_1213_committed )
varlabel(share211_1213_committed "O\&G Exposure" );
#delimit cr

#delimit;
estout  ols_port  ols_portj ols_portnj ols_nport ols_nportnj ols_gov  ols_tot  using non_origOLS.tex, 
mlabels("Port" "\shortstack{Port\\Jumbo}" "\shortstack{Port\\Non-Jumbo}" "Non-Port" "Non-Port Non-Jumbo" "Gov"  "All"  ) 
replace cells(b(star fmt(%9.3f)) se(par fmt(3)))
starlevels(* 0.10 ** 0.05 *** 0.01)
style(tex) 
stats(N r2 BC FE CC, fmt(0 2) labels("Number of Observations" "R-squared" "Bank Controls" "Fixed Effects" "County Controls" ))
collabels(none) 
drop(`bank_controls' `county_controls' *.st_code  _cons)
order(share211_1213_committed )
varlabel(share211_1213_committed "O\&G Exposure" );
#delimit cr


#delimit;
estout  ols_porto  ols_portjo ols_portnjo  ols_nporto ols_nportnjo ols_govo ols_toto  using origOLS.tex, 
mlabels( "Port" "\shortstack{Port\\Jumbo}" "\shortstack{Port\\Non-Jumbo}"   "Non-Port" "Non-Port Non-Jumbo" "Gov"  "All" ) 
replace cells(b(star fmt(%9.3f)) se(par fmt(3)))
starlevels(* 0.10 ** 0.05 *** 0.01)
style(tex) 
stats(N r2 BC FE CC, fmt(0 2) labels("Number of Observations" "R-squared" "Bank Controls" "Fixed Effects" "County Controls" ))
collabels(none) 
drop(`bank_controls' `county_controls' *.st_code _cons)
order(share211_1213_committed )
varlabel(share211_1213_committed "O\&G Exposure" );
#delimit cr

#delimit;
estout fe_portoL fe_portjoL fe_portnjoL  fe_nportoL   fe_nportnjoL fe_govoL fe_totoL   using table_altexp_mortL.tex, 
mlabels( "Port"  "\shortstack{Port\\Jumbo}" "\shortstack{Port\\Non-Jumbo}"  "Non-Port" "Non-Port Non-Jumbo" "Gov" "All") 
replace cells(b(star fmt(%9.3f)) se(par fmt(3)))
starlevels(* 0.10 ** 0.05 *** 0.01)
style(tex) 
stats(N_tot r2_tot BC FE CC, fmt(0 2) labels("Number of Observations" "R-squared" "Bank Controls" "Fixed Effects" "County Controls" ))
collabels(none) 
drop(`bank_controls' )
order(share211_1213_totloans share211_1213_totassets )
varlabel(share211_1213_totloans "O\&G Loans/Total Loans" 
share211_1213_totassets "O\&G Loans/Total Assets" );
#delimit cr


#delimit;
estout fe_portoA fe_portjoA fe_portnjoA  fe_nportoA   fe_nportnjoA fe_govoA fe_totoA   using table_altexp_mortA.tex, 
mlabels( "Port"  "\shortstack{Port\\Jumbo}" "\shortstack{Port\\Non-Jumbo}"  "Non-Port" "Non-Port Non-Jumbo" "Gov" "All") 
replace cells(b(star fmt(%9.3f)) se(par fmt(3)))
starlevels(* 0.10 ** 0.05 *** 0.01)
style(tex) 
stats(N_tot r2_tot BC FE CC, fmt(0 2) labels("Number of Observations" "R-squared" "Bank Controls" "Fixed Effects" "County Controls" ))
collabels(none) 
drop(`bank_controls' )
order(share211_1213_totloans share211_1213_totassets )
varlabel(share211_1213_totloans "O\&G Loans/Total Loans" 
share211_1213_totassets "O\&G Loans/Total Assets" );
#delimit cr
*/


#delimit;
estout fe_portoE fe_portjoE fe_portnjoE  fe_nportoE   fe_nportnjoE fe_govoE fe_totoE   using table_altexp_mortE.tex, 
mlabels( "Port"  "\shortstack{Port\\Jumbo}" "\shortstack{Port\\Non-Jumbo}"  "Non-Port" "Non-Port Non-Jumbo" "Gov" "All") 
replace cells(b(star fmt(%9.3f)) se(par fmt(3)))
starlevels(* 0.10 ** 0.05 *** 0.01)
style(tex) 
stats(N_tot r2_tot BC FE CC, fmt(0 2) labels("Number of Observations" "R-squared" "Bank Controls" "Fixed Effects" "County Controls" ))
collabels(none) 
drop(`bank_controls' )
order(share211_1213_totloans share211_1213_totassets )
varlabel(share211_1213_totloans "O\&G Loans/Total Loans" 
share211_1213_totassets "O\&G Loans/Total Assets" );
#delimit cr


/*



#delimit;
estout  fe_ltvnjnew fe_ltvnjold fe_ltvnjfull fe_ltvjnew fe_ltvjold fe_ltvjfull fe_ltvallfull using ltv.tex, 
mlabels( "New"  "Existing" "All"  "New"  "Existing" "All"  "All") 
replace cells(b(star fmt(%9.3f)) se(par fmt(3)))
starlevels(* 0.10 ** 0.05 *** 0.01)
style(tex) 
stats(N_tot r2_tot BC FE CC, fmt(0 2) labels("Number of Observations" "R-squared" "Bank Controls" "Fixed Effects" "County Controls" ))
collabels(none) 
drop(`bank_controls' d_ltv_lag*)
order(share211_1213_committed )
varlabel(share211_1213_committed "O\&G Exposure" );
#delimit cr



#delimit;
estout  fe_dtibnjnew fe_dtibnjold fe_dtibnjfull fe_dtibjnew fe_dtibjold fe_dtibjfull fe_dtiballfull using dtib.tex, 
mlabels( "New"  "Existing" "All"  "New"  "Existing" "All"  "All") 
replace cells(b(star fmt(%9.3f)) se(par fmt(3)))
starlevels(* 0.10 ** 0.05 *** 0.01)
style(tex) 
stats(N_tot r2_tot BC FE CC, fmt(0 2) labels("Number of Observations" "R-squared" "Bank Controls" "Fixed Effects" "County Controls" ))
collabels(none) 
drop(`bank_controls' d_dtib_lag*)
order(share211_1213_committed )
varlabel(share211_1213_committed "O\&G Exposure" );
#delimit cr



#delimit;
estout  fe_ficonjnew fe_ficonjold fe_ficonjfull fe_ficojnew fe_ficojold fe_ficojfull fe_ficoallfull using fico.tex, 
mlabels( "New"  "Existing" "All"  "New"  "Existing" "All"  "All") 
replace cells(b(star fmt(%9.3f)) se(par fmt(3)))
starlevels(* 0.10 ** 0.05 *** 0.01)
style(tex) 
stats(N_tot r2_tot BC FE CC, fmt(0 2) labels("Number of Observations" "R-squared" "Bank Controls" "Fixed Effects" "County Controls" ))
collabels(none) 
drop(`bank_controls' d_fico_lag*)
order(share211_1213_committed )
varlabel(share211_1213_committed "O\&G Exposure" );
#delimit cr




