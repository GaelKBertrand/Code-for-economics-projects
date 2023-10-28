// Generate directories with roots as: GaelK.Bertrand/Replication exercise STATA

use "/new_directory_path/Data/Y9C_condensed.dta", clear
sort id_rssd date
merge 1:1 id_rssd date using "/new_directory_path/loans3_clean.dta"
drop _merge
sort id_rssd date
merge 1:1 id_rssd date using "/new_directory_path/Temporary_Files/mortgage_varsforfig_retain.dta"
drop _merge
merge 1:1 id_rssd date using "/new_directory_path/Temporary_Files/y14_sum.dta"
drop _merge
sort id_rssd date
merge 1:1 id_rssd date using "/new_directory_path/Data/securities/STATA/agency_MBS_data2_agg.dta"
drop _merge
sort id_rssd date
merge 1:1 id_rssd date using "/new_directory_path/Data/securities/STATA/agencies_by_date_bhc2.dta"
drop _merge

// Local variables: ltv fico inter dti
// Uncomment the following code if necessary
// local mortlist ltv fico inter dti
// foreach i of local mortlist {
//     drop `i'
//     rename `i'r `i'
// }

merge 1:1 id_rssd date using "/new_directory_path/Output/Temporary/y14_resloans.dta"
drop _merge
sort id_rssd
merge id_rssd using "/new_directory_path/Output/Temporary/temp_BKS_oil_post_KM_bhc_share.dta"
drop _merge

// Choose breakpoint
local b 217  // 2014:Q2
// local b 216  // 2014:Q1

// Use the updated treasury data
replace treas = bhck0213 + bhck1287

// LINE REDACTED DUE TO CONFIDENTIAL INFORMATION

// Generate liquidity ratio
replace lcr_proxy = (treas + total_agency_MBS + bhck1290 + bhck1293 + bhck1295 + bhck1298 + bhck0081 + bhck0395 + bhck0397) / total_assets

// Generate leverage ratio
gen lev = total_assets / equity_cap

// LINE REDACTED DUE TO CONFIDENTIAL INFORMATION

// Merge in 2011 controls (made in BKS_pre_pre_period_controls.do)
sort id_rssd
merge id_rssd using "/new_directory_path/pre_preperiod.dta"
drop _merge

// Choose exposure variable for the quad diagram
local type committed
// local type equity

bysort id_rssd date: keep if _n == 1
bysort id_rssd: egen sharetemp = max(share211_1213_`type')
replace share211_1213_`type' = sharetemp

// Percentile cutoffs
bysort id_rssd: gen firstb = _n == 1
replace firstb = . if firstb == 0
egen p10 = pctile(share211_1213_`type' * firstb), p(10)
egen p90 = pctile(share211_1213_`type' * firstb), p(90)
egen p25 = pctile(share211_1213_`type' * firstb), p(25)
egen p75 = pctile(share211_1213_`type' * firstb), p(75)
egen p33 = pctile(share211_1213_`type' * firstb), p(33)
egen p66 = pctile(share211_1213_`type' * firstb), p(66)
egen p50 = pctile(share211_1213_`type' * firstb), p(50)

gen h50p = share211_1213_`type' >= p50
gen l50b = share211_1213_`type' < p50
gen h75p = share211_1213_`type' >= p75
gen h75b = share211_1213_`type' < p75
gen h66p = share211_1213_`type' >= p66
gen h90p = share211_1213_`type' >= p90
gen l33b = share211_1213_`type' <= p33
gen l25b = share211_1213_`type' <= p25
gen l10b = share211_1213_`type' <= p10
gen h7590 = share211_1213_`type' >= p75 & share211_1213_`type' > p90
gen l1025 = share211_1213_`type' > p10 & share211_1213_`type' <= p25

// Splice Together RWA Ratio
gen weight = rwa / total_assets
bysort id_rssd: egen weight219 = max(weight * (date == 219)) // 2014:Q4
bysort id_rssd: egen weight220 = max(weight * (date == 220))
replace weight = weight - (weight220 - weight219) if date > 219

// Splice RWA
bysort id_rssd: egen rwa219 = max(rwa * (date == 219)) // 2014:Q4
bysort id_rssd: egen rwa220 = max(rwa * (date == 220))
replace rwa = rwa - (rwa220 - rwa219) if date > 219

replace cap_ratio1 = tier1cap / total_assets

// Rename variables and update log values
local y9variables lev roa totsecs treas MBSA lcr_proxy rlest const famop famcl ci cc auto
foreach i of local y9variables {
    gen ln`i' = ln(`i')
    replace ln`i' = `i' if `i' == roa
    replace ln`i' = `i' if `i' == lcr_proxy
    replace ln`i' = `i' if `i' == weight
    replace ln`i' = `i' if `i' == lev
    gen ln`i'_resid = .
    foreach k of local banklist {
        capture reg ln`i' date if date <= `b' & firstbd == 1 & id_rssd == `k'
        capture replace ln`i'_resid = ln`i' - _b[date] * date - _b[_cons] if firstbd == 1 & id_rssd == `k'
        capture gen bank`k' = id_rssd == `k'
        capture replace bank`k' = . if bank`k' == 0
        bysort id_rssd: egen ln`i'_resid`k' = max(ln`i'_resid * datedum * bank`k')
        bysort id_rssd: egen ln`i'_resid`k'min = min(ln`i'_resid * datedum * bank`k')
        capture replace ln`i'_resid`k' = ln`i'_resid`k'min if ln`i'_resid`k' == 0 & ln`i'_resid`k'min < 0
        capture replace ln`i'_resid = ln`i'_resid - ln`i'_resid`k' if firstbd == 1 & id_rssd == `k'
        capture drop ln`i'_resid`k' bank`k'
    }
    foreach j of local variable {
        bysort date: egen ln`i'`j'_resid = mean(ln`i'_resid * `j' * firstbd)
    }
}

// Regression PLOTS
// Bank level regressions
foreach i of local y9variables {
    bysort id_rssd: egen d20142_`i' = max(`i' * (date == yq(2014,2)))
    bysort id_rssd: egen d20153_`i' = max(`i' * (date == yq(2015,3)))
    bysort id_rssd: egen d20161_`i' = max(`i' * (date == yq(2016,1)))
    bysort id_rssd: egen d20123_`i' = max(`i' * (date == yq(2012,3)))
    gen delta161_142_`i' = ln(d20161_`i' / d20142_`i')
    gen delta153_142_`i' = ln(d20153_`i' / d20142_`i')
    gen delta142_123_`i' = ln(d20142_`i' / d20123_`i')
}

egen bank_tag = tag(id_rssd)

// Drop data beyond a certain date
drop if date > 224

// Local variables
local share share211_1213_committed
// local share share211_1213_equity

gen middle = share211_1213_committed < p75 & share211_1213_committed > p25
bysort id_rssd: egen pre_ass = max(total_assets * (date == 210))

sum `share' if bank_tag
local se = r(sd)
gen normshare = `share' / `se'
drop bank_tag

// More regression and graphing code...

// Generate interaction variables
gen levdelta = delta142_123_lev
gen tcmdelta = delta142_123_tcm
gen roadelta = delta142_123_roa
gen ti_idelta = delta142_123_ti_i
gen uscapratio1 = cap_ratio1
gen normcapratio1 = cap_ratio1 / se
gen sharesq = `share' ^ 2
gen lendelta = delta142_123_totsecs

// Graphing
foreach i in share211_1213_committed share211_1213_equity {
    twoway (scatter delta142_123_lev `i' if bank_tag, mlabel(id_rssd) mlabsize(tiny)) (lfit delta142_123_lev `i' if bank_tag)
    title("2012:Q3 to 2014:Q2", size(small)) xtitle("Bank-Level Leverage Delta", size(vsmall)) ytitle("Bank-Level Share of" "`i'", size(vsmall))
    graph export "/new_directory_path/Output/Scatterplot/delta142_123_lev_`i'.png", replace
    graph close
    twoway (scatter delta142_123_lev `i' if middle, mlabel(id_rssd) mlabsize(tiny)) (lfit delta142_123_lev `i' if middle)
    title("2012:Q3 to 2014:Q2", size(small)) xtitle("Bank-Level Leverage Delta", size(vsmall)) ytitle("Bank-Level Share of" "`i'", size(vsmall))
    graph export "/new_directory_path/Output/Scatterplot/delta142_123_lev_`i'_middle.png", replace
    graph close
    local xvariable `i'
    foreach j in levdelta tcmdelta roadelta ti_idelta uscapratio1 normcapratio1 sharesq lendelta {
        local xlabel "`j'"
        twoway (scatter `j' `xvariable' if bank_tag, mlabel(id_rssd) mlabsize(tiny)) (lfit `j' `xvariable' if bank_tag)
        title("2012:Q3 to 2014:Q2", size(small)) xtitle("Bank-Level `xlabel'", size(vsmall)) ytitle("Bank-Level Share of" "`i'", size(vsmall))
        graph export "/new_directory_path/Output/Scatterplot/`j'_`xvariable'_`i'.png", replace
        graph close
        twoway (scatter `j' `xvariable' if middle, mlabel(id_rssd) mlabsize(tiny)) (lfit `j' `xvariable' if middle)
        title("2012:Q3 to 2014:Q2", size(small)) xtitle("Bank-Level `xlabel'", size(vsmall)) ytitle("Bank-Level Share of" "`i'", size(vsmall))
        graph export "/new_directory_path/Output/Scatterplot/`j'`xvariable'_`i'_middle.png", replace
        graph close
    }
    local xvariable delta142_123_lev
    foreach j in sharesq normcapratio1 {
        local xlabel "`j'"
        scatter `j' `xvariable' if bank_tag || ///
        lfit `j' `xvariable' if bank_tag || ///
        lfitci `j' `xvariable' if bank_tag
        title("2012:Q3 to 2014:Q2", size(small)) xtitle("Bank-Level `xlabel'", size(vsmall)) ytitle("Bank-Level Share of" "`i'", size(vsmall))
        graph export "/new_directory_path/Output/Scatterplot/`j'`xvariable'_`i'.png", replace
        graph close
        scatter `j' `xvariable' if middle || ///
        lfit `j' `xvariable' if middle || ///
        lfitci `j' `xvariable' if middle
        title("2012:Q3 to 2014:Q2", size(small)) xtitle("Bank-Level `xlabel'", size(vsmall)) ytitle("Bank-Level Share of" "`i'", size(vsmall))
        graph export "/new_directory_path/Output/Scatterplot/`j'`xvariable'_`i'_middle.png", replace
        graph close
    }
}

// END OF CODE


