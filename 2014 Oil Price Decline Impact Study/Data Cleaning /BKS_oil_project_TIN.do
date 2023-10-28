/*
   BKS_oil_project_TIN.do: This script handles the cleaning of available TINs and addresses missing TINs.
   It identifies TINs that are inappropriately common to multiple obligors and generates TINs where obligors can be reliably distinguished.
*/

set more off

*-------------------------------------------------------------------------------
* First stage: Exact matches of obligor names in other entries where TIN is present

gen period = all_periods  // Using all_periods or quarter_y14 to require observations with TIN from the same period
fill_rb tin obligorname period  // The fill_rb.ado searches for values of TIN for the same obligorname and period and fills the missing ones with the modal value
drop period
egen tincode = group(tin)

* Second stage: Using reclink2 for US firms

*-------------------------------------------------------------------------------
* Create a snapshot
preserve
	do BKS_oil_project_reclink2.do
restore

* Merge in missing TINs with matched clean obligor names
capture drop _merge
sort obligorname
merge obligorname using "GaelK.Bertrand/Replication exercise STATA/Data/missingtins_matched.dta"
gen flag_missm = missing(tincode) & _merge == 3 & ~missing(tincode_missingm)
replace tincode = tincode_missingm if flag_missm == 1
drop _merge

* Merge in missing unmatched clean obligor names (cleanobligorname used as tincode)
sort obligorname
merge obligorname using "GaelK.Bertrand/Replication exercise STATA/Data/missingtins_unmatched.dta"
gen flag_missu = missing(tincode) & _merge == 3 & ~missing(tincode_missingu)
replace tincode = tincode_missingu if flag_missu == 1
drop _merge

* Merge in multi-obligor TINs flag (multiobltin)
sort tincode
merge tincode using "GaelK.Bertrand/Replication exercise STATA/Data/problemtins_flag.dta"
drop _merge

* Merge in multi-obligor TINs with a matched TIN, matched by clean obligor name
sort obligorname
merge obligorname using "GaelK.Bertrand/Replication exercise STATA/Data/multiobligormatch.dta"
gen flag_multim = _merge == 3 & ~missing(tincode_multimatch) & multiobltin == 1
replace tincode = tincode_multimatch if flag_multim == 1
drop _merge

* Merge in multi-obligor TINs with an unmatched TIN, TIN replaced by clean obligor name
sort obligorname
merge obligorname using "GaelK.Bertrand/Replication exercise STATA/Data/multiobligorumatch.dta"
gen flag_multium = _merge == 3 & ~missing(tincode_multiumatch) & multiobltin == 1 & flag_multim == 0
replace tincode = tincode_multiumatch if flag_multium == 1
drop _merge

* Ignore TIN codes for unmerged multi-obligors in making exposure: will drop later
replace tincode = . if multiobltin == 1 & flag_multim == 0 & flag_multium == 0

drop tincode_missingm tincode_missingu tincode_multimatch tincode_multiumatch
