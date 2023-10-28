/* BKS_oil_project_industries.do focuses on data cleaning related to NAICS industry codes, incorporating cross-references with SIC and GIC classifications. */
set more off

*-------------------------------------------------------------------------------
* Admin
cd "GaelK.Bertrand/Replication exercise STATA"

preserve
	do "BKS_oil_project_industry_crosswalks.do" // Creates crosswalks invoked below
restore

tostring industrycode, replace

gen ind_code_length = strlen(industrycode)
gen missing_industrycode = ind_code_length == 0

gen bad_industrycode = 0
replace bad_industrycode = 1 if industrycodetype == 1 & (ind_code_length < 2 | ind_code_length > 6) // Not conforming to NAICS code length (allowing for full code and subindustries)
replace bad_industrycode = 1 if industrycodetype == 2 & (ind_code_length < 2 | ind_code_length > 4) // Not conforming to SIC code length (allowing for full code and subindustries)
replace bad_industrycode = 1 if industrycodetype == 3 & (ind_code_length < 2 | ind_code_length > 8) // Not conforming to GIC code length (allowing for full code and subindustries)

* SIC (https://en.wikipedia.org/wiki/Standard_Industrial_Classification)
replace bad_industrycode = 1 if industrycodetype == 2 & inlist(substr(industrycode, 1, 2), "00", "18", "19")

gen sic = industrycode if industrycodetype == 2 & !bad_industrycode

gen sic_maj_group_present = ind_code_length >= 2 & industrycodetype == 2 & !bad_industrycode
gen sic_ind_group_present = ind_code_length >= 3 & industrycodetype == 2 & !bad_industrycode
gen sic_ind_present = ind_code_length >= 4 & industrycodetype == 2 & !bad_industrycode

gen sic_maj_group = substr(industrycode, 1, 2) if sic_maj_group_present
gen sic_ind_group = substr(industrycode, 1, 3) if sic_ind_group_present
gen sic_ind = substr(industrycode, 1, 4) if sic_ind_present

* Merge SIC-NAICS crosswalks
capture drop _merge
sort sic
merge sic using "your_new_directory/sic_naics_crosswalk_2012.dta"
gen sic2012_merge = _merge
gen merged_sic2012 = sic2012_merge == 3 // Successful merge
tab sic2012_merge if industrycodetype == 2
drop _merge
sort sic
merge sic using "your_new_directory/sic_naics_crosswalk_2002.dta"
gen sic2002_merge = _merge
gen merged_sic2002 = sic2002_merge == 3 // Successful merge
tab sic2002_merge if industrycodetype == 2
drop _merge
sort sic
merge sic using "your_new_directory/sic_naics_crosswalk_1997.dta"
gen sic1997_merge = _merge
gen merged_sic1997 = sic1997_merge == 3 // Successful merge
tab sic1997_merge if industrycodetype == 2
drop _merge
sort sic
merge sic using "your_new_directory/sic_23d_naics_crosswalk.dta"
gen sic23d_merge = _merge
gen merged_sic23d = sic23d_merge == 3 // Successful merge
tab sic23d_merge if industrycodetype == 2
drop _merge

* GICS (https://en.wikipedia.org/wiki/Global_Industry_Classification_Standard)
gen temp_flag = 0 // Statement was too long to set bad_industrycode directly
replace temp_flag = 1 if industrycodetype == 3 & inlist(substr(industrycode, 1, 2), "10", "15", "20", "25", "30")
replace temp_flag = 1 if industrycodetype == 3 & inlist(substr(industrycode, 1, 2), "35", "40", "45", "50", "55")
replace bad_industrycode = 1 if industrycodetype == 3 & !temp_flag
drop temp_flag

gen gics = industrycode if industrycodetype == 3 & !bad_industrycode

gen gics_sector_present = ind_code_length >= 2 & industrycodetype == 3 & !bad_industrycode
gen gics_ind_group_present = ind_code_length >= 4 & industrycodetype == 3 & !bad_industrycode
gen gics_ind_present = ind_code_length >= 6 & industrycodetype == 3 & !bad_industrycode

gen gics_sector = substr(industrycode, 1, 2) if gics_sector_present
gen gics_ind_group = substr(industrycode, 1, 4) if gics_ind_group_present
gen gics_ind = substr(industrycode, 1, 6) if gics_ind_present

* Merge GICS-NAICS crosswalks
sort gics
merge gics using "your_new_directory/gics_naics_crosswalk.dta"
gen gics_merge = _merge
gen merged_gics = gics_merge == 3 // Successful merge
tab gics_merge if industrycodetype == 3
drop _merge

* NAICS (https://en.wikipedia.org/wiki/North_American_Industry_Classification_System)
gen temp_flag = 0 // Statement was too long to set bad_industrycode directly
replace temp_flag = 1 if industrycodetype == 1 & inlist(substr(industrycode, 1, 2), "11", "21", "22", "23", "31")
replace temp_flag = 1 if industrycodetype == 1 & inlist(substr(industrycode, 1, 2), "33", "42", "44", "45", "48", "49")
replace temp_flag = 1 if industrycodetype == 1 & inlist(substr(industrycode, 1, 2), "51", "52", "53", "54", "55", "56")
replace temp_flag = 1 if industrycodetype == 1 & inlist(substr(industrycode, 1, 2), "61", "62", "71", "72", "81", "92")
replace bad_industrycode = 1 if industrycodetype == 1 & !temp_flag
drop temp_flag

gen naics = industrycode if industrycodetype == 1 & !bad_industrycode

* Use merged data from SIC
gen orig_naics = naics
replace naics = naics_sic12 if missing(naics) & merged_sic2012
replace naics = naics_sic02 if missing(naics) & merged_sic2002
replace naics = naics_sic97 if missing(naics) & merged_sic1997
replace naics = naics_sic23d if missing(naics) & merged_sic23d
replace naics = naics_gics if missing(naics) & merged_gics

drop naics_sic12 naics_sic02 naics_sic97 naics_sic23d

* Make subsectors etc.
gen naics_length = strlen(naics)
gen naics_sector_present = naics_length >= 2
gen naics_sub_sector_present = naics_length >= 3
gen naics_group_present = naics_length >= 4

gen ind2 = substr(naics, 1, 2) if naics_sector_present // ind2 = naics_sector
gen ind3 = substr(naics, 1, 3) if naics_sub_sector_present // ind3 = naics_sub_sector
gen ind4 = substr(naics, 1, 4) if naics_group_present // ind4 = naics_group

gen missing_ind3 = missing(ind3)

* How many different ind3 are there for each tincode
bysort tincode ind3: gen f_tincode_ind3 = _n == 1 if !missing_ind3
bysort tincode: egen n_ind3_by_tincode = total(f_tincode_ind3), missing

bysort tincode ind3: gen n_obs_ind3_by_tincode = _N if !missing_ind3
bysort tincode missing_ind3: gen n_obs_by_tincode_and_ind3pres = _N if !missing_ind3
bysort tincode ind3: gen share_ind3_by_tincode = n_obs_ind3_by_tincode / n_obs_by_tincode_and_ind3pres if !missing(tincode) & !missing_ind3

* Replace with modal ind3
* Note: We have share_ind3_by_tincode and pre_clean_ind3 to check how binding this
* assumption is.
bysort tincode: egen N_of_modal_ind3 = max(n_obs_ind3_by_tincode)
bysort tincode ind3: gen modal_ind3_flag = n_obs_ind3_by_tincode == N_of_modal_ind3 // Note that there could be more than one ind3 that is modal

bysort tincode: gen modal_ind3_positions = _n if f_tincode_ind3 & modal_ind3_flag //!missing(ind3) is already implicit in modal_ind3_flag
by tincode: egen first_modal_ind3_position = min(modal_ind3_positions) // Identify the modal ind3 that appears first (somewhat arbitrary but reasonable)

by tincode: gen modal_ind3_observation = _n == first_modal_ind3_position
gen auxvar2 = ""
by tincode: replace auxvar2 = ind3 if modal_ind3_observation
by tincode: replace auxvar2 = auxvar2[first_modal_ind3_position] if missing(auxvar2)

* Create cleaned ind3
gen pre_clean_ind3 = ind3 // Save before overwriting
replace ind3 = auxvar2 // Overwrite all of the non-modal ind3 (missing or not)

drop auxvar2 modal_ind3_observation first_modal_ind3_position modal_ind3_positions modal_ind3_flag ///
    N_of_modal_ind3 share_ind3_by_tincode n_obs_by_tincode_and_ind3pres n_obs_ind3_by_tincode ///
    n_ind3_by_tincode f_tincode_ind3 naics_*_present merged_* bad_industrycode *_merge

drop sic sic_maj_group_present sic_ind_group_present sic_ind_present sic_maj_group ///
    sic_ind_group sic_ind naics_des_sic12 naics_des_sic02 naics_des_sic97 sic_des_23d gics ///
    gics_sector_present gics_ind_group_present gics_ind_present gics_sector gics_ind_group ///
    gics_ind gics_des naics_gics naics_gics_des orig_naics naics_length

compress
