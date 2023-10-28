/* Generate 'tot_new' as the total of 'new_loan' for each 'fips' and 'date' group */
bysort fips date: egen tot_new = total(new_loan)

/* Create 'fips_date_tag' to tag 'fips' and 'date' combinations */
egen fips_date_tag = tag(fips date)

/* Replace 'fips_date_tag' with missing values for rows where it's equal to 0 */
replace fips_date_tag = . if fips_date_tag == 0

/* Calculate the mean of 'fips_date_tag' times 'tot_new' for each 'fips' group */
bysort fips: egen mean_trans = mean(fips_date_tag * tot_new)

/* Keep only the first observation for each group based on 'first_obs' variable */
keep if first_obs == 1

/* Capture the 'merge' error and drop the '_merge' variable */
capture drop _merge

/* Sort the dataset by 'county_fips' */
sort county_fips

/* Merge with the dataset in "/classified/l1jrk0b_l1rmb01/Data/ahrf_clean.dta" */
merge county_fips using "/classified/l1jrk0b_l1rmb01/Data/ahrf_clean.dta"

/* Generate 'st' as the first two characters of 'fips' */
gen st = substr(fips, 1, 2)

/* Encode 'st' into 'st_code' */
encode st, gen(st_code)

/* Create 'fips_tag' to tag 'county_fips' */
egen fips_tag = tag(county_fips)

/* Generate 'lndens' as the natural logarithm of 'populationdensitypersquaremile' */
gen lndens = ln(populationdensitypersquaremile)

/* Generate 'lnhdens' as the natural logarithm of 'housingunitdensitypersquaremile' */
gen lnhdens = ln(housingunitdensitypersquaremile)

/* Calculate 'percvac' as the ratio of 'vacanthousingunits' to 'housingunits' */
gen percvac = vacanthousingunits / housingunits

/* Generate 'npop' and 'lnpop' as the natural logarithm of 'populationestimate' */
gen npop = ln(populationestimate)
gen lnpop = ln(populationestimate)

/* Create 'lnhvalue' as the natural logarithm of 'medianhomevalue' */
gen lnhvalue = ln(medianhomevalue)

/* Generate 'lnrent' as the natural logarithm of 'mediangrossrent' */
gen lnrent = ln(mediangrossrent)

/* Calculate 'percvet' as the ratio of 'veteranpopulationestimate' to 'populationestimate' */
gen percvet = veteranpopulationestimate / populationestimate

/* Create 'lnhhi' as the natural logarithm of 'medianhouseholdincome' */
gen lnhhi = ln(medianhouseholdincome)

/* Calculate 'frac3plus' as the ratio of households with 3 or more persons to 'numberhouseholds' */
gen frac3plus = (householdswith3persons + householdswith4persons + householdswith5persons + householdswith6ormorepersons) / numberhouseholds

/* Drop rows where 'fips' corresponds to Guam, Puerto Rico, or the Virgin Islands */
drop if fips == "66010" | fips == "69010" // Guam
drop if substr(fips, 1, 2) == "72" // Puerto Rico
drop if substr(fips, 1, 2) == "78" // Virgin Islands

/* Drop rows with missing values in 'lnpop' */
drop if missing(lnpop)

/* Compress the dataset to save storage space */
compress
