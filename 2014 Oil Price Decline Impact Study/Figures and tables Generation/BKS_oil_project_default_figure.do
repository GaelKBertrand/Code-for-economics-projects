* Set the working directory
cd "C:\GaelK.Bertrand\Replication exercise STATA"

* Load the data
use "/classified_info_data/temp_BKS_oil_post_KM_prep.dta", clear

* Generate indicators for specific industries
gen ind211 = ind3 == "211"
replace ind211 = . if ind211 == 0
gen nonind211 = ind211 == .
replace nonind211 = . if nonind211 == 0
gen ind3_old = ind3

* Note: You can test other industries by uncommenting the following lines
/*
drop ind211
gen ind211 = ind3 == "331"
replace ind211 = . if ind211 == 0
*/

* Data cleaning for industry codes
drop ind3 ind4
gen ind3 = substr(naics, 1, 3)
gen ind4 = substr(naics, 1, 4)
gen ind5 = substr(naics, 1, 5)

* Create an indicator for specific industries
gen induser = ind5 == "S0020" | ind4 == "2212" | ind5 == "32412" | ind3 == "481" | ind3 == "486" ///
            | ind4 == "S001" | ind5 == "32419" | ind3 == "483" | ind5 == "32513" | ind4 == "2211"  ///
            | ind3 == "484" | ind3 == "482" | ind5 == "32512" | ind5 == "2122A" | ind5 == "32518"

* Exclude "ind211" if it was previously labeled as "211"
replace induser = . if ind3_old == "211"
replace induser = . if induser == 0

* List of industry indicators
local indlist ind211 nonind211 induser

* Filter data based on date
drop if date >= 227
drop if date < 210

* Data cleaning and transformation
gen missing_pastdue = missing(pastdue)
gen renew_dum = ~missing(year(renewaldate)) & year(renewaldate) < 9999
destring cumulativechargeoffs, force replace
replace pastdue = 1 if pastdue > 0
gen anychargeoff = cumulativechargeoffs > 0
replace anychargeoff = . if missing(cumulativechargeoffs)
replace pastdue = . if missing_pastdue == 1
gen utilized = utilizedexposure > 0
replace utilized = . if utilized == 0
gen yearacc = year(nonaccrualdate)
gen pastorcharge = pastdue == 1 | anychargeoff == 1 | yearacc ~= 9999
replace pastorcharge = . if pastdue == . & anychargeoff == . & yearacc == .

* Calculate summary statistics by industry
foreach i of local indlist {
    bysort date : egen tot_`i'_ce = total(committedexposure * `i')
    by date : egen tot_`i'_ue = total(utilizedexposure * `i')
    by date : egen tot_`i'_co = total(cumulativechargeoffs * `i')
    by date : egen tot_`i'_past = total(pastdue * `i')
    by date : egen tot_`i'_pastfrac = mean(pastdue * `i')
    by date : egen tot_`i'_pastcofrac = mean(pastorcharge * `i')
    by date : egen tot_`i'_pastfracu = mean(pastdue * `i' * utilizedexposure)
    by date : egen tot_`i'_pastdollc = total((pastdue * `i') * committedexposure)
    by date : egen tot_`i'_pastdollu = total((pastdue * `i') * utilizedexposure)
}

* Calculate summary statistics for all industries
by date : egen tot_past_frac = mean(pastdue)
by date : egen tot_pastco_frac = mean(pastorcharge)
by date : egen tot_past_fracu = mean(pastdue * utilized)

* Utilization Rate Plot
bysort date: egen tot_n211_comm = total(nonind211 * committedexposure * lineofcredit)
bysort date: egen tot_n211_util = total(nonind211 * utilizedexposure * lineofcredit)
bysort date: egen tot_211_comm = total(ind211 * committedexposure * lineofcredit)
bysort date: egen tot_211_util = total(ind211 * utilizedexposure * lineofcredit)
bysort date: egen tot_induser_comm = total(induser * committedexposure * lineofcredit)
bysort date: egen tot_induser_util = total(induser * utilizedexposure * lineofcredit)

gen tot_211_rate = tot_211_util / tot_211_comm
gen tot_n211_rate = tot_n211_util / tot_n211_comm
gen tot_induser_rate = tot_induser_util / tot_induser_comm

* Calculate the loan utilization rate
gen rate = utilizedexposure / committedexposure
replace rate = . if termall == 1
bysort date: egen tot_211_ratem = mean(rate * ind211)
bysort date: egen tot_n211_ratem = mean(rate * nonind211)
bysort date: egen tot_induser_ratem = mean(rate * induser)

* Calculate the loan utilization rate for all industries
foreach i of local indlist {
    by date: egen bank_`i'_pastfrac = mean(pastdue * `i')
    by date: egen bank_`i'_pastcofrac = mean(pastorcharge * `i')
    by date: egen bank_`i'_co = total(cumulativechargeoffs * `i')
    by date: egen bank_`i'_pc = total((pastdue == 1 | yearacc ~= 9999) * `i' * utilizedexposure)
}

by date: egen bank_pastcofrac = mean(pastorcharge)

* Calculate statistics for banks with higher and lower utilization rates
bysort bhc date: egen firstbd = _n == 1
replace firstbd = . if firstbd == 0
bysort date: egen bank_ceH = total(bank_ce * h75p * firstbd)
bysort date: egen bank_ceL = total(bank_ce * l25b * firstbd)
bysort date: egen bank_pcH = total(bank_pc * h75p * firstbd)
bysort date: egen bank_pcL = total(bank_pc * l25b * firstbd)
bysort date: egen bank_coH = total(bank_co * h75p * firstbd)
bysort date: egen bank_coL = total(bank_co * l25b * firstbd)

foreach i of local indlist {
    by date: egen bank_`i'_pastfracH = mean(bank_`i'_pastfrac * h75p * firstbd)
    by date: egen bank_`i'_pastfracL = mean(bank_`i'_pastfrac * l25b * firstbd)
    by date: egen bank_`i'_pcfrac211H = mean(bank_`i'_pastcofrac * h75p * firstbd)
    by date: egen bank_`i'_pcfrac211L = mean(bank_`i'_pastcofrac * l25b * firstbd)
    by date: egen bank_`i'_pctotH = total(pastorcharge * h75p * `i')
    by date: egen bank_`i'_pctotL = total(pastorcharge * l25b * `i')
    by date: egen bank_`i'_coH = total(bank_`i'_co * h75p * firstbd)
    by date: egen bank_`i'_coL = total(bank_`i'_co * l25b * firstbd)
    by date: egen bank_`i'_pcH = total(bank_`i'_pc * h75p * firstbd)
    by date: egen bank_`i'_pcL = total(bank_`i'_pc * l25b * firstbd)

    gen frac_`i'_loanspcaH = (bank_`i'_pcH + bank_`i'_coH) / bank_ceH
    gen frac_`i'_loanspcaL = (bank_`i'_pcL + bank_`i'_coL) / bank_ceL
}

gen frac__loanspcaH = (bank_pcH + bank_coH) / bank_ceH
gen frac__loanspcaL = (bank_pcL + bank_coL) / bank_ceL

by date: egen bank__pastcofracH = mean(bank_pastcofrac * h75p * firstbd)
by date: egen bank__pastcofracL = mean(bank_pastcofrac * l25b * firstbd)
by date: egen bank_totH = total(h75p)
by date: egen bank_totL = total(l25b)

gen frac211H = bank_ind211_pctotH / bank_totH
gen fracn211H = bank_nonind211_pctotH / bank_totH
gen frac211L = bank_ind211_pctotL / bank_totL
gen fracn211L = bank_nonind211_pctotL / bank_totL

* Check correlations
bysort bhc year: egen bank_problem211 = mean(pastorcharge * ind211)
bysort bhc year: egen bank_nonguar211 = mean((guarantorflag == 4) * ind211)
bysort bhc year: egen bank_unsec211 = mean((securitytype == 6) * ind211)
destring pd, replace force
bysort bhc year: egen bank_pd211 = mean(pd * ind211)

* Create additional tags for date, year, and banks
egen bank_date = tag(bhc date)
egen bank_year = tag(bhc year)

* Perform regressions and correlations
reg bank_problem211 share211_1213_committed if year >= 2015 & bank_year == 1, cluster(bhc)
pwcorr bank_problem211 share211_1213_committed if year >= 2015 & bank_year == 1, sig
pwcorr bank_nonguar211 share211_1213_committed if year <= 2014 & bank_year == 1, sig
pwcorr bank_unsec211 share211_1213_committed if year <= 2014 & bank_year == 1, sig
pwcorr bank_pd211 share211_1213_committed if year <= 2014 & bank_year == 1, sig

* Clean up data
bysort date: keep if _n == 1
gen date2 = ""
replace date2 = "2012:3" if date == 210
replace date2 = "2012:4" if date == 211
replace date2 = "2013:1" if date == 212
replace date2 = "2013:2" if date == 213
replace date2 = "2013:3" if date == 214
replace date2 = "2013:4" if date == 215
replace date2 = "2014:1" if date == 216
replace date2 = "2014:2" if date == 217
replace date2 = "2014:3" if date == 218
replace date2 = "2014:4" if date == 219
replace date2 = "2015:1" if date == 220
replace date2 = "2015:2" if date == 221
replace date2 = "2015:3" if date == 222
replace date2 = "2015:4" if date == 223
replace date2 = "2016:1" if date == 224
replace date2 = "2016:2" if date == 225	// Amended 11/29/2016 before new wave of data (for plots not regressions)
replace date2 = "2016:3" if date == 226 // Amended 11/29/2016 before new wave of data (for plots not regressions)
drop date
rename date2 date

* Export the data to an Excel file
export excel date tot_past_frac tot_past_fracu tot_ind211_ce tot_ind211_ue tot_ind211_co tot_ind211_past tot_ind211_pastfrac tot_ind211_pastfracu tot_ind211_pastdollc tot_ind211_pastdollu ///
    tot_nonind211_ce tot_nonind211_ue tot_nonind211_co tot_nonind211_past tot_nonind211_pastfrac tot_nonind211_pastfracu tot_nonind211_pastdollc tot_nonind211_pastdollu tot_induser_pastfrac ///
    tot_pastco_frac tot_ind211_pastcofrac tot_nonind211_pastcofrac tot_induser_pastcofrac  ///
    frac211H fracn211H  frac211L fracn211L tot_211_ratem  tot_n211_ratem tot_induser_ratem OGcounty_nonind nonOGcounty_nonind ///
    using "/GaelK.Bertrand/Replication exercise STATA/Tables/defaultplot", firstrow(variables) replace

