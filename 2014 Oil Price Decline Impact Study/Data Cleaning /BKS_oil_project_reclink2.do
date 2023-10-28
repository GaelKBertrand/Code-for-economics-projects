/*
   BKS_oil_project_reclink2.do employs reclink2 and various filters to allocate tincodes
   to firms that can be confidently matched and to avoid using tincodes that are shared
   by clearly distinct obligors.
*/

set more off

*-------------------------------------------------------------------------------
* Restrict the sample to the United States and standardize names.
* NOTE: THIS ONLY NEEDS TO BE RUN ONCE, so it should be commented out if obligor_tin_standard.dta
* has already been created.

keep if country == "US"
keep obligorname tincode
drop if missing(obligorname)
bysort obligorname tincode: keep if _n == 1

stnd_compname obligorname, gen(stnname) patpath(GaelK.Bertrand/Replication exercise STATA/patternfiles)
save "GaelK.Bertrand/Replication exercise STATA/obligor_tin_standard.dta", replace // Save intermediate standardized obligor-tin pairs

*-------------------------------------------------------------------------------
* Identify multiple obligors for tin and see if they can be established as matching
* using simple rules based on common words, etc.

* Look for the dodgy tins - use the matching of words among adjacent obligors as
* a metric
use "GaelK.Bertrand/Replication exercise STATA/obligor_tin_standard.dta", clear // Uncomment if standardization has already been run above
drop if missing(tincode)
bysort tincode obligorname: gen f_obl_tin = _n == 1
bysort tincode: egen n_obl_for_tin = total(f_obl_tin)
gen firsto = substr(stnname, 1, 1)
gen flag_the = substr(stnname, 1, 3) == "THE"

sort tincode stnname
by tincode: gen flag = firsto[_n] ~= firsto[_n-1] & _n > 1 & flag_the[_n] == 0 & flag_the[_n-1] == 0
by tincode: egen flagmax = max(flag)
keep if flagmax == 1 & n_obl_for_tin > 1 // Necessary condition for problem tin: first letter of obligorname doesn't match - Keep only those tins where there is an obligorname with different first letters

gen match = 0
bysort tincode: replace match = 1 if regexm(stnname[_n], stnname[_n-1])
bysort tincode: replace match = 1 if regexm(stnname[_n-1], stnname[_n])

forval i = 1/10 {
    by tincode: replace match = 1 if regexm(word(stnname[_n], `i'), word(stnname[_n-1], `i')) & wordcount(stnname) >= `i'
    by tincode: replace match = 1 if regexm(word(stnname[_n-1], `i'), word(stnname[_n], `i')) & wordcount(stnname) >= `i'
    by tincode: replace match = 1 if regexm(word(stnname[_n], `i'+1), word(stnname[_n-1], `i')) & wordcount(stnname) >= `i' + 1
    by tincode: replace match = 1 if regexm(word(stnname[_n-1], `i'+1), word(stnname[_n], `i')) & wordcount(stnname) >= `i' + 1
    by tincode: replace match = 1 if regexm(word(stnname[_n], `i'+2), word(stnname[_n-1], `i')) & wordcount(stnname) >= `i' + 2
    by tincode: replace match = 1 if regexm(word(stnname[_n-1], `i'+2), word(stnname[_n], `i')) & wordcount(stnname) >= `i' + 2
    by tincode: replace match = 1 if regexm(word(stnname[_n], `i'+3), word(stnname[_n-1], `i')) & wordcount(stnname) >= `i' + 3
    by tincode: replace match = 1 if regexm(word(stnname[_n-1], `i'+3), word(stnname[_n], `i')) & wordcount(stnname) >= `i' + 3
}

by tincode: egen meanmatch = mean(match)

* Apply tolerance for a match and look for TINs where it still seems like a lot of
* the obligor names fail to match their neighbors and signal that the TIN
* is common to different firms and, thus, would be inappropriate to use as a firm identifier.
keep if meanmatch < 0.75 // Keeping "Problem Tins": At least 75% of obligor names (within the same tin) did NOT match their neighbor. Note it will miss problem-tins with large chunks of the same tin at a time.
save "GaelK.Bertrand/Replication exercise STATA/problemtins_full.dta", replace
keep tincode
gen multiobltin = 1 // All of these retained tins (currently in memory) apparently have "genuinely" multiple obligors
bysort tincode: keep if _n == 1
sort tincode
save "GaelK.Bertrand/Replication exercise STATA/problemtins_flag.dta", replace  // Merge this to the main dataset to flag problem tin codes

*-------------------------------------------------------------------------------
* Take out obviously multiple obligor name TINs, leaving TINs that to a high degree
* are probably for a unique obligor.

use "GaelK.Bertrand/Replication exercise STATA/obligor_tin_standard.dta", clear // Uncomment if obligor_tin_standard.dta has already been created (and comment out the previous section)
drop if missing(tincode)
bysort tincode stnname: keep if _n == 1
keep stnname tincode
sort tincode
merge tincode using "GaelK.Bertrand/Replication exercise STATA/problemtins_flag.dta"  // Merge to identify the TINs with "genuinely" multiple obligors
drop if multiobltin == 1
drop _merge
sort stnname
save "GaelK.Bertrand/Replication exercise STATA/tin_standard_1m_nomulti.dta", replace  // Save the legit stnname-tin pairs that aren't obviously multi-obligor cases (there may be some limited noise)

*-------------------------------------------------------------------------------
* For multi-obligors TINs with a matched TIN found.
* If a bank (A) uses a TIN that is uniquely associated with an obligor name and we find that obligor name in the problem TINs,
* then we take bank A's TIN and overwrite the bad TIN for that obligor name.

use "GaelK.Bertrand/Replication exercise STATA/problemtins_full.dta", clear
sort stnname
merge m:m stnname using "GaelK.Bertrand/Replication exercise STATA/tin_standard_1m_nomulti.dta"

drop if missing(obligorname)
keep if _merge == 3
keep tincode obligorname
bysort obligorname: keep if _n == 1
rename tincode tincode_multimatch

sort obligorname
save "GaelK.Bertrand/Replication exercise STATA/multiobligormatch.dta", replace // TinSet#1: Multi-obligors TINs with a matched stnname found.

*-------------------------------------------------------------------------------
* Multi-obligors TINs with no matched stnname found.

use "GaelK.Bertrand/Replication exercise STATA/problemtins_full.dta", clear
sort stnname
merge m:m stnname using "GaelK.Bertrand/Replication exercise STATA/tin_standard_1m_nomulti.dta"

drop if missing(obligorname)
drop if _merge == 3
drop tincode
egen tincode_temp = group(stnname)

gen double tincode = tincode_temp + 50000000 // QUESTION: Should we not use max(existing tincodes) rather than 50000...
bysort obligorname: keep if _n == 1
keep tincode obligorname
rename tincode tincode_multiumatch

sort obligorname
save "GaelK.Bertrand/Replication exercise STATA/multiobligorumatch.dta", replace // TinSet#2: Multi-obligors TINs with no matched stnname found.

*-------------------------------------------------------------------------------
* Update missing TINs by matching on stnname where we only use TIN-stnname pairs
* that are "good".

use "GaelK.Bertrand/Replication exercise STATA/obligor_tin_standard.dta", clear
keep if missing(tincode)
sort stnname
merge m:m stnname using "GaelK.Bertrand/Replication exercise STATA/tin_standard_1m_nomulti.dta", update
drop if missing(obligorname)

*-------------------------------------------------------------------------------
* There are still some missings at this point so these stnname were not present in the "good" dataset,
* so we might as well treat them as the unique identifier and create an artificial TIN for them.

preserve
keep if missing(tincode)  // This will drop the matched stnnames (_merge ==4) as well (since tins were updated)
drop tincode
egen tincode_temp = group(stnname)
gen double tincode = tincode_temp + 500000000  // Added one more zero than above
bysort obligorname: keep if _n == 1
keep tincode obligorname
rename tincode tincode_missingu
sort obligorname
save "GaelK.Bertrand/Replication exercise STATA/missingtins_unmatched.dta", replace // TinSet#3: Missing TINs with no matched clean-obligor names. Define new TIN as a clean obligor name
restore

*-------------------------------------------------------------------------------
* We only keep the entries for which the TIN has been filled based on the stnname
* match with "good" TIN-stnname pairs.

keep if _merge == 4 // 4 means updated the master TINs based on matches with using
keep tincode obligorname
bysort obligorname: keep if _n == 1
rename tincode tincode_missingm
sort obligorname
save "GaelK.Bertrand/Replication exercise STATA/missingtins_matched.dta", replace // TinSet#4 Missing TINs with matched clean-obligor name: New TIN is the matched TIN in the dataset
