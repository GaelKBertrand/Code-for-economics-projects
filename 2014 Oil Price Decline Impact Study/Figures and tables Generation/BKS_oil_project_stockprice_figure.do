* Set the root directory for data
cd "GaelK.Bertrand/Replication exercise STATA/Data"

* MONTHLY MARKET CAP

* Load the relevant data files
use "monthly_mcap.dta", clear
sort date id_rssd

* Merge with stock price data
merge date id_rssd using "../Output/oil_exposure_index/stockpriceswithsandp_reshaped2.dta"
keep if _merge == 3
drop _merge

* Merge with bank data
sort id_rssd
merge id_rssd using "../Output/Temporary/bank_data.dta"
drop _merge

* Drop missing values
drop if missing(share211_1213_committed)

* Rename columns for clarity
rename mkt_cap mcap
rename USEquity equity

* Calculate 'pivot' variable
gen pivot = (year(date) == 2014) & (month(date) == 6)

* Calculate percentile cutoffs
bysort id_rssd: egen p25 = pctile(share211_1213_committed*pivot), p(25)
bysort id_rssd: egen p75 = pctile(share211_1213_committed*pivot), p(75)

* Identify 'high_bank' and 'low_bank'
gen high_bank = share211_1213_committed >= p75
replace high_bank = . if high_bank == 0
gen low_bank = share211_1213_committed <= p25
replace low_bank = . if low_bank == 0

* Calculate logarithmic differences
foreach i in mcap equity {
    bysort id_rssd: egen `i'_20142 = max(`i'*pivot)
    gen logdiff_`i' = ln(`i'/`i'_20142)
    bysort date: egen high_`i' = mean(high_bank*logdiff_`i')
    bysort date: egen low_`i' = mean(low_bank*logdiff_`i')
}

* Keep the first observation for each date
bysort date: keep if _n == 1

* Export results to Excel
export excel date high_mcap low_mcap high_equity low_equity using "Tables/mcapplot", firstrow(variables) replace

* Create 'month,' 'year,' and 'date2' variables
gen month = month(date)
gen year = year(date)
gen date2 = ym(year, month)
drop if date2 > ym(2016, 1)
format date2 %tmCCYY:nn

* Label variables for clarity
label variable high_mcap "Exposure Above 75th Percentile"
label variable low_mcap "Exposure Below 25th Percentile"
label variable high_equity "Exposure Above 75th Percentile"
label variable low_equity "Exposure Below 25th Percentile"

* Create line plots for stock price data
twoway (line high_equity date2, sort lpattern(shortdash) lcolor(red)) (line low_equity date2, sort lpattern(shortdash) lcolor(blue)), title("A: Stock Price", size(huge)) name(equity_graph, replace) xtitle("") scheme(s1color) yscale(range(-.6 .3) titlegap(*10)) ylabel(-.6(.1).3, labsize(large)) xlabel(624(6)672, angle(30) labsize(large)) legend(size(medium) region(lwidth(none))) yline(0, lcolor(gs11)) ytitle("Percent Deviation from 2014:2")
twoway (line high_mcap date2, sort lpattern(shortdash) lcolor(red)) (line low_mcap date2, sort lpattern(shortdash) lcolor(blue)), title("B: Market Capitalization", size(huge)) name(mcap_graph, replace) xtitle("") scheme(s1color) yscale(range(-.6 .3) titlegap(*10)) ylabel(-.6(.1).3, labsize(large)) xlabel(624(6)672, angle(30) labsize(large)) legend(size(medium) region(lwidth(none))) yline(0, lcolor(gs11)) ytitle("")

* Combine and save the graphs
grc1leg equity_graph mcap_graph, rows(1) iscale(.8) xsize(12) ysize(5) scheme(s1color) name(stock_combine, replace) saving("Temporary_Files/stock_combine", replace)
graph display stock_combine, xsize(12) ysize(5)
graph export "Tables/stock_combine.pdf", replace

* MONTHLY (ORIGINAL STOCK PRICE PLOT)

* Load original stock price data
use "../Output/oil_exposure_index/stockpriceswithsandp.dta", clear

* Remove duplicate dates
drop if date1[_n] == date1[_n+1]

* Format the 'date' variable
gen temp = mofd(date)
format temp %tm
drop date
rename temp date
order date

* Export results to Excel
export excel date high low using "Tables/stockplot", firstrow(variables) replace

* Create line plots for stock price data
twoway (line low date) (line high date) (line med_low date) (line med_high date)
