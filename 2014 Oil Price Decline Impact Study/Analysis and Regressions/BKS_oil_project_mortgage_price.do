* Set more off
set more off

* Rename variables for clarity
rename ltv_ratio_orig ltv
rename creditbureau_score_orig fico
rename dti_ratio_backend_orig dtib
rename dti_ratio_frontend_orig dtif
rename int_rate_orig inter

* Data cleaning and handling outliers
replace fico = . if fico <= 300
replace fico = . if fico >= 850
replace ltv  = . if ltv  <= 0
replace ltv  = . if ltv  > 1.2
replace inter = . if inter <= 0
replace dtib = . if dtib <= 2
replace dtib = . if dtib >= 99
replace dtif = . if dtif <= 2
replace dtif = . if dtif >= 99

* Generate pre_period variable
gen pre_period = pre_period_dot
replace pre_period = 0 if missing(pre_period_dot)

* Create local macro for variable list
local varlist ltv fico dtib dtif inter

* Generate all, nj, and j variables
local jumbolist all nj j
gen all = porto
gen nj  = portnjo
gen j   = portjo

* Iterate through variables for data cleaning and transformation
foreach i of local varlist {
    replace `i' = . if orig_date < yq(2012,3)
}

* NEW LOANS
foreach k of local jumbolist {
    foreach i of local varlist {
        bysort id_rssd county_fips date: egen `i'_date = wtmean(`i'), weight(origination_wins*new_loan*`k')
        bysort id_rssd county_fips: egen pre_`i' = mean(`i'_date*pre_period_dot*loan_date_tag)
        by id_rssd county_fips: egen post_`i' = mean(`i'_date*post_period_dot*loan_date_tag)
        gen d_`i'_new`k' = post_`i' - pre_`i'
        bysort id_rssd date: egen `i'_bhc_date = wtmean(`i'), weight(origination_wins*new_loan*`k')
        by id_rssd: egen pre_`i'_20123 = mean(`i'_bhc_date*dot20123*date_bank_tag)
        by id_rssd: egen post_`i'_20142 = mean(`i'_bhc_date*dot20142*date_bank_tag)
        gen d_`i'_lag_new`k' = post_`i'_20142 - pre_`i'_20123
        drop pre_`i' post_`i' post_`i'_20142 pre_`i'_20123 `i'_date `i'_bhc_date
    }
}

* OLD LOANS
foreach k of local jumbolist {
    foreach i of local varlist {
        bysort id_rssd county_fips date: egen `i'_date = wtmean(`i'), weight(origination_wins*old_loan*`k')
        bysort id_rssd county_fips: egen pre_`i' = mean(`i'_date*pre_period_dot*loan_date_tag)
        by id_rssd county_fips: egen post_`i' = mean(`i'_date*post_period_dot*loan_date_tag)
        gen d_`i'_old`k' = post_`i' - pre_`i'
        bysort id_rssd date: egen `i'_bhc_date = wtmean(`i'), weight(origination_wins*old_loan*`k')
        by id_rssd: egen pre_`i'_20123 = mean(`i'_bhc_date*dot20123*date_bank_tag)
        by id_rssd: egen post_`i'_20142 = mean(`i'_bhc_date*dot20142*date_bank_tag)
        gen d_`i'_lag_old`k' = post_`i'_20142 - pre_`i'_20123
        drop pre_`i' post_`i' post_`i'_20142 pre_`i'_20123 `i'_date `i'_bhc_date
    }
}

* FULL BALANCE SHEET
foreach k of local jumbolist {
    foreach i of local varlist {
        bysort id_rssd county_fips date: egen `i'_date = wtmean(`i'), weight(origination_wins*`k')
        bysort id_rssd county_fips: egen pre_`i' = mean(`i'_date*pre_period_dot*loan_date_tag)
        by id_rssd county_fips: egen post_`i' = mean(`i'_date*post_period_dot*loan_date_tag)
        gen d_`i'_full`k' = post_`i' - pre_`i'
        bysort id_rssd date: egen `i'_bhc_date = wtmean(`i'), weight(origination_wins*`k')
        by id_rssd: egen pre_`i'_20123 = mean(`i'_bhc_date*dot20123*date_bank_tag)
        by id_rssd: egen post_`i'_20142 = mean(`i'_bhc_date*dot20142*date_bank_tag)
        gen d_`i'_lag_full`k' = post_`i'_20142 - pre_`i'_20123
        drop pre_`i' post_`i' post_`i'_20142 pre_`i'_20123 `i'_date `i'_bhc_date
    }
}

* Drop temporary variables
drop all nj j

* Compress the dataset
compress
