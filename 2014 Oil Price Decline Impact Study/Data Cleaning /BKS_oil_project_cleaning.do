/*************************************************************
BKS_oil_project_cleaning.do
This STATA script performs essential procedures to clean and prepare the data for more complex transformations.
**************************************************************/
cd "GaelK.Bertrand/Replication exercise STATA"

set more off

/*************************************************************
Trivial admin
Generate a unique identifier for this database before removing duplicate entries.
Identify variables that need to be converted into uppercase strings.
**************************************************************/

gen orig_dataset_id = _n

local str_list bhc_name country otherfacilitytype otherfacilitypurpose

foreach x in `str_list' {
    replace `x' = strupper(`x')
}

/*************************************************************
Banks
Redacted lines contain confidential information related to the Y14 data.
Use id_rssd to determine the bank.
**************************************************************/

*** LINE REDACTED DUE TO CONFIDENTIAL INFORMATION

rename id_rssd bhc

*** LINE REDACTED DUE TO CONFIDENTIAL INFORMATION

/*************************************************************
Dates
Generate Y14Q vintage and various date variables.
Admin variable for all periods.
Clean and prepare origination and new loan data.
**************************************************************/

gen quarter_y14 = date
format quarter_y14 %tq

gen y_2011 = 2011 * (date > 203 & date <= 207)
gen y_2012 = 2012 * (date > 207 & date <= 211)
gen y_2013 = 2013 * (date > 211 & date <= 215)
gen y_2014 = 2014 * (date > 215 & date <= 219)
gen y_2015 = 2015 * (date > 219 & date <= 223)
gen y_2016 = 2016 * (date > 223 & date <= 227)
gen year_y14 = y_2011 + y_2012 + y_2013 + y_2014 + y_2015 + y_2016

rename datefinancials financialsdate
foreach i in origination maturity file financials nonaccrual renewal {

    gen quarter`i' = qofd(`i'date)
    format quarter`i' %tq

    gen year`i' = yofd(`i'date)
    format year`i' %ty

}

gen all_periods = 1

gen orig_9999_flag = yearorigination == 9999
gen missing_orig = missing(originationdate)
gen bad_orig = orig_9999_flag | missing_orig
gen clean_orig = !bad_orig
gen q_since_orig = quarter_y14 - quarterorigination if clean_orig
gen new_loan = q_since_orig == 0
replace new_loan = . if bad_orig

gen new_loan_confirmed = 1 if new_loan == 1
replace new_loan_confirmed = 0 if new_loan_confirmed ~= 1

/*************************************************************
Obligor Names
Clean and prepare obligor names.
*************************************************************/

gen bad_obligor_1 = inlist(obligorname, "Individual", "TRUST", "Restricted Customer", "INDIVIDUAL", "IndividualFamily Trust")
gen bad_obligor_2 = inlist(obligorname, "FOREIGN OBLIGOR", "MASKED", "CONFIDENTIAL", "GOVERNMENT GUARANTEED")
replace obligorname = "" if bad_obligor_1 | bad_obligor_2 | inlist(obligorname, "0", "#N/A", "NA")

drop bad_obligor_1 bad_obligor_2

/*************************************************************
Cleaning TIN
Clean and prepare TIN (Tax Identification Number) data.
*************************************************************/

replace tin = subinstr(tin, " ", "", .)
replace tin = subinstr(tin, "-", "", .)
replace tin = subinstr(tin, ".", "", .)
replace tin = "" if strlen(tin) != 9

gen f2_tin = substr(tin, 1, 2) if strlen(tin) == 9

replace tin = "" if inlist(f2_tin, "00", "07", "08", "09", "17", "18", "19", "28")
replace tin = "" if inlist(f2_tin, "29", "49", "78", "79", "A0", "A2", "A4", "A7")
replace tin = "" if inlist(f2_tin, "A8", "DE")

drop f2_tin

/*************************************************************
Public Securities
Flag listed firms and clean CUSIP data.
*************************************************************/

gen listed = !missing(tkr) & !inlist(tkr, "NA", "MASKED", "UNKN", "0", "na", "NONE", "n/a")
replace tkr = "" if inlist(tkr, "NA", "MASKED", "UNKN", "0", "na", "NONE", "n/a")
gen missing_tkr = missing(tkr)

replace cusip = "" if inlist(cusip, "NA", "na", "MASKED", "UNKN", "NONE")
replace cusip = "" if strlen(cusip) != 6
gen missing_cusip = missing(cusip)

/*************************************************************
Cleaning Quantities and Winsorizing
Prepare and winsorize selected variables.
*************************************************************/

foreach i in utilizedexposure committedexposure netincomecurrent totalassetscurrent {
    gen orig_`i' = `i'
    destring `i', replace force
    gen missing_`i' = missing(`i')
}

gen mat_flag = date >= 209
gen above_mat = committedexposure >= 1000000 & !missing(committedexposure)
gen above_mat_buff = committedexposure >= (1.2 * 1000000) & !missing(committedexposure)

/*************************************************************
Conserve Memory
Compress the dataset to conserve memory.
*************************************************************/

compress
