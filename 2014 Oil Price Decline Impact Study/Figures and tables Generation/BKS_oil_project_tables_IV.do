/******** MAKE LATEX TABLES: COMPILE THEM IN COMPILER.TEX *********/

// Change directories to where LaTeX tables are generated
cd "GaelK.Bertrand/Replication exercise STATA/Tables"

// Define local macros for bank and loan controls
local bank_controlsagg lag_logdeltaci_agg e_share_agg ln_assets_agg roa_agg foreign npl_share_comm_agg tier1rwa_share_agg ci_share_agg loan_share_agg res_share_agg deposit_share_agg co_share_agg
local bank_controls lag_logdeltaci e_share ln_assets_mean roa_mean foreign npl_share_comm_mean tier1rwa_share_mean ci_share_mean loan_share_mean res_share_mean deposit_share_mean co_share_mean

local loan_controls avg_age_termall age2 age3
local loan_controlsagg avg_age_agg_termall ageagg2 ageagg3
local firm_controls multi_bank
local intersmall inter_size small_size
local interrisky inter_risky risky_pre
local interext inter_ext ext
local interold inter_old old
local intermulti inter_multib4 multi_bank4
local interallols inter_ext inter_open inter_multib4 inter_old
local interallols_cont ext openlinepre multi_bank4 old
local interallfe inter_ext inter_open inter_multib4 inter_old
local multi multi_bank

// Choose the Net Worth Variable
local networth delta_mcap
local nwname "$\Delta$ Market Cap"

// Generate LaTeX tables using estout
#delimit;
estout feintens7 olsintens6 feexit3 olsexit1 using interactionsIV.tex, ///
  mlabels("FE" "OLS" "FE" "OLS") ///
  replace cells(b(star fmt(%9.3f)) se(par fmt(3))) ///
  starlevels(* 0.10 ** 0.05 *** 0.01) ///
  style(tex) ///
  stats(N_tot r2_tot FE, fmt(0 2) labels("Number of Observations" "R-squared" "Fixed Effects")) ///
  collabels(none) ///
  drop(`firm_controls' `loan_controls' `bank_controls') ///
  order(`networth' nw_ext ext nw_multib4 multi_bank4 nw_open openlinepre nw_old old) ///
  varlabel(`networth' "`nwname'" nw_ext "`nwname'*External Finance Firm" ext "External Finance Firm" ///
           nw_old "`nwname'*(Length of Relationship)" old "Length of Relationship" ///
           nw_multib4 "`nwname'*(Number of Bank Relationships)" multi_bank4 "Number of Bank Relationships" ///
           nw_open "`nwname'*(Share Utilized)" openlinepre "Share Utilized" _cons "Constant");
#delimit cr

// More estout commands for generating LaTeX tables, if needed

