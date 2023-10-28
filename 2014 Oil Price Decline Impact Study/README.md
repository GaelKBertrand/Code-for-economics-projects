# Project Title: Analyzing Banks' Response to Oil Price Declines - STATA Implementation
# Replicated Project Paper: Bidder, Rhys, Krainer, John and Shapiro, Adam, (2021), <a href="https://EconPapers.repec.org/RePEc:red:issued:19-100">De-leveraging or de-risking? How banks cope with loss</a>, <i>Review of Economic Dynamics</i>, <b>39</b>, issue , p. 100-127.

## Overview

This STATA implementation explores how banks respond to a net worth shock resulting from the 2014 oil price declines. The project leverages variations in banks' loan exposure to industries adversely affected by these declines. By analyzing granular data obtained through the Federal Reserve's stress testing programs, we investigate banks' behavior in response to this economic shock.

## Objectives of the paper 

- Examine the impact of oil price declines on banks' lending practices.
- Analyze credit tightening effects on corporate lending and mortgage lending.
- Investigate changes in mortgage lending, particularly for government-backed securities.
- Evaluate how banks rebalance their portfolios in response to the shock.

## Methodology

I replicate the paper analysis using STATA, a powerful statistical software widely used for data analysis and manipulation. STATA enables us to process and analyze the granular data obtained under the Federal Reserve's stress testing programs, facilitating comprehensive exploration of banks' behavior.

## Data

### Data Sources
The analysis in this project utilizes data from the quarterly FR Y-14Q and monthly FR Y-14M filings, which are required of bank holding companies (BHCs) with more than $50 billion in assets. These filings have been in place since 2012 and contain detailed data on banks' balance sheet exposures, capital components, and categories of pre-provision net revenue. The primary purpose of these filings is to assess the capital adequacy of banks, in support of supervisory stress testing programs mandated by the Dodd-Frank Act.

### Commercial and Residential Loans
The datasets include commercial and residential loans, originating from 28 and 26 banks, respectively. These loans serve as key variables and bank controls in the analysis of commercial and residential lending.

- **Commercial Loans**: Data on commercial loans are extracted from the quarterly corporate loan schedule in the FR Y-14Q, providing a 'credit register' with loan-level information, borrower and lender identification, and various loan characteristics. In 2014:Q2, just before the decline in oil prices, these loans totaled $1.17 trillion, encompassing approximately 70 percent of the $1.69 trillion in commercial and industrial loans extended by the entire BHC population filing a FR Y-9C report.

- **Mortgage Loans**: The dataset contains monthly loan-level data on banks' mortgage positions, including borrower and mortgage characteristics. It allows for differentiation between on-balance sheet (portfolio loans) and off-balance sheet loans, particularly those sold to government-sponsored enterprises (GSEs) yet retained for servicing.

### Unique Data Features
Several distinctive characteristics of the data are noteworthy:

- **Multiple Asset Classes**: The data allow for the exploration of multiple asset classes. Within the corporate loan dataset, it distinguishes between credit lines and term lending, while within the mortgage dataset, it can classify loans as securitizable (government loans or conforming to Fannie and Freddie's requirements).

- **Tracking Borrower Behavior**: Detailed knowledge of borrowers enables the construction of a measure of bank exposure to oil and gas drillers, a central element in the study. It allows for the tracking of the same borrower across multiple banks, facilitating the study of within-borrower variations and borrower behavior when switching banks.

- **Loan Size Range**: Unlike some other data sources, such as syndicated loans data, the data extend to smaller loans, including those with values as low as $1 million.

### Additional Data Sources
In addition to the FR Y-14 filings, the insights are drawn from the Federal Reserve's Senior Loan Officer Opinion Survey (SLOOS), which provides information on changes in banks' lending standards. Additionally, the use is made of confidential bank-specific survey responses from the SLOOS. The data also rely on the Federal Deposit Insurance Corporation (FDIC) Summary of Deposits data to construct an instrument for the exposure variable based on branch location.

### Data Availability
For access to the FR Y-14Q and FR Y-14M filings, please refer to the official sources associated with the Federal Reserve's stress testing programs. These filings are available for bank holding companies (BHCs) with assets exceeding $50 billion.

The SLOOS data and the FDIC Summary of Deposits data are publicly available and can be obtained from the respective sources.

Note: Researchers and analysts can use this data to replicate the findings presented in this project or for related research purposes.

## How to Run the Analysis

To run the analysis for this project, follow these steps:

1. Begin by executing the `BKS_oil_project_driver.do` do file. This program encompasses all underlying programs used in the paper.

**Confidentiality Note**: Please be aware that certain lines of code within this program have been redacted due to confidentiality concerns related to the Y14 data. This same practice was done by the authors of the paper. 

2. If you have permission from the Federal Reserve Board of Governors to access the Y14 data, you can request unredacted code and data. To obtain access to the unredacted code and data, please refer to the official source [here](https://www.federalreserve.gov/reportforms/forms/FR_Y-14Q20200331_i.pdf).

By following these steps, users can execute the analysis and obtain results, provided they have the necessary permissions for accessing confidential data.

### Important Note Regarding Directory Paths

Before executing the provided Stata code, it's crucial to review and adjust the directory paths to match your specific file structure and data locations. The code references directory paths that may differ from your setup, and updating them is essential to ensure the code runs without errors.

**Directory Paths to Review:**

1. Please verify and modify the root directory used in the code to align with your directory structure. The code assumes a root directory with the following path: `GaelK.Bertrand/Replication exercise STATA`. Ensure that you write your own path correctly

2. Additionally, take a close look at any file paths, such as data file locations or outputs. Make sure that they point to the correct directories on your system.

By carefully adjusting these directory paths, you'll be able to seamlessly run the code and obtain the desired results. Keep in mind that any changes to directory paths should be consistent with your file organization and data storage setup.


## Key Findings

1. **Credit Tightening:** Exposed banks responded to the net worth shock by tightening credit on corporate lending and on mortgages to be held on their balance sheets.

2. **Mortgage Expansion:** Exposed banks expanded credit for mortgages to be securitized, particularly government-backed ones. This indicates a strategic portfolio rebalancing.

3. **Risk Management:** Banks adjusted their portfolios to lower their average risk weight, rather than reducing the size of their balance sheets. This cross-balance sheet perspective provides valuable insights into bank behavior.

4. **Credit Channels:** Borrowers demonstrated a propensity to seek alternative financing when facing credit tightening from initially chosen banks. This project sheds light on how borrowers adapt in response to changes in the lending environment.

5. **Minimal Impact on Borrowers:** Ultimately, this analysis reveals a minimal impact on borrowers' overall funding. This finding serves as a benchmark for studies examining credit channels during crisis periods.

## Usage

This repository contains the STATA code and scripts used to conduct the analysis. Researchers and professionals can utilize this code to replicate the study's findings or adapt it for related research.

## Copyright

This project is based on the research paper: Bidder, Rhys, Krainer, John and Shapiro, Adam, (2021), <a href="https://EconPapers.repec.org/RePEc:red:issued:19-100">De-leveraging or de-risking? How banks cope with loss</a>, <i>Review of Economic Dynamics</i>, <b>39</b>, issue , p. 100-127.  published by Elsevier. Please respect copyright and licensing agreements when using this code for your own research or analysis.

## Contributions

The replication exercise builds on the main code used by the paper's authors. The replication exercise aim was to reproduce the results in the paper and confirm the analysis in the paper. 

## Acknowledgments

I acknowledge the support and data provided by the Federal Reserve's stress testing programs, which made this analysis possible.
