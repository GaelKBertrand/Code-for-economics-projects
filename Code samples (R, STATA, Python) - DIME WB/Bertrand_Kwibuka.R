# Clear all the current workspace work
rm(list=ls())

# Start logging
sink("/Users/gaelk.bertrand/Desktop/UCB/clean_data/Bertrand_Kwibuka.log")

# Set up working directory
setwd("/Users/gaelk.bertrand/Desktop/UCB")

# Load or install required packages/dependencies
if (!require("tidyverse")) install.packages("tidyverse")
if (!require("haven")) install.packages("haven")
if (!require("janitor")) install.packages("janitor")
if (!require("skimr")) install.packages("skimr")
if (!require("ggplot2")) install.packages("ggplot2")
if (!require("plm")) install.packages("plm")
if (!require("car")) install.packages("car")
if (!require("lmtest")) install.packages("lmtest")
if (!require("broom")) install.packages("broom")
if (!require("tableone")) install.packages("tableone")

# Load the 'tableone' package
library(plm)
library(car)
library(lmtest)
library(broom)
library(tableone)



# Q1. IMPORT DATA
data <- read_dta("/Users/gaelk.bertrand/Desktop/UCB/combined_data.RData")

# Data exploration to have some insights about data before executing any other task
# Display dataset information
str(data)
# Calculate summary statistics for all variables
summary(data)
# Export the summary statistics as a CSV file
write.csv(summary(data), "/Users/gaelk.bertrand/Desktop/UCB/pre-analysis/summary_statistics.csv")

# Data Quality Check
table(data$nb_visit_post_carto)

# Check for outliers in the variables of interest in this data task 'survey_complete' and 'number of visits post carto'
hist(data$survey_complete, main="Histogram of survey_complete", xlab="survey_complete", breaks=10)
ggsave("/Users/gaelk.bertrand/Desktop/UCB/pre-analysis/histogram_survey_complete.png")

hist(data$nb_visit_post_carto, main="Histogram of nb_visit_post_carto", xlab="nb_visit_post_carto", breaks=10)
ggsave("/Users/gaelk.bertrand/Desktop/UCB/pre-analysis/histogram_nb_visit_post_carto.png")

# Q2. LIST AND DROP DUPLICATES
# List the duplicates based on a unique identifier variable in the dataset: 'compound_code'
duplicated_data <- data[duplicated(data$compound_code),]
print(duplicated_data)

# Drop the duplicates if they exist
data <- data[!duplicated(data$compound_code),]

# Check if duplicates are all removed
sum(duplicated(data$compound_code))

# Dropping incomplete surveys using variable 'survey_complete':
data <- data[data$survey_complete == 1,]

# Save the new dataset
write_dta(data, "/Users/gaelk.bertrand/Desktop/UCB/clean_data/combined_data.RData")

# Q3. MERGING WITH nearest_property DATASET
# Read the CSV file
nearest_property <- read.csv("/Users/gaelk.bertrand/Desktop/UCB/nearest_property.csv")

# Save the dataset in R data format ".RData"
save(nearest_property, file="/Users/gaelk.bertrand/Desktop/UCB/clean_data/nearest_property.RData")

# Load master data "combined_data.RData" again
load("/Users/gaelk.bertrand/Desktop/UCB/clean_data/combined_data.RData")

# Get the list of variable names in the master dataset
master_vars <- names(data)

# Load the using dataset or secondary data
load("/Users/gaelk.bertrand/Desktop/UCB/clean_data/nearest_property.RData")

# Load the using dataset or secondary data
nearest_property <- read_dta("/Users/gaelk.bertrand/Desktop/UCB/clean_data/nearest_property.RData")

# Get the list of variable names in the using dataset
using_vars <- names(nearest_property)

# Compare variable names in both datasets
common_vars <- intersect(master_vars, using_vars)
print(common_vars)

# Check on the type of the unique identifier (compound_code) in both datasets before merging
# For the Main dataset
str(data$compound_code)
# Sort the dataset based on the unique identifier
data <- data[order(data$compound_code),]
saveRDS(data, "/Users/gaelk.bertrand/Desktop/UCB/clean_data/combined_data.RData")

# For the Using dataset
str(nearest_property$compound_code)
# Sort the dataset based on the unique identifier
nearest_property <- nearest_property[order(nearest_property$compound_code),]
saveRDS(nearest_property, "/Users/gaelk.bertrand/Desktop/UCB/clean_data/nearest_property.RData")

# After finding that the type of the unique identifier differs, now I can address it:
# Recode 'compound_code' into a long format in the 'combined_data' like in 'nearest_property'
data <- readRDS("/Users/gaelk.bertrand/Desktop/UCB/clean_data/combined_data.RData")
# Convert compound_code to string first
data$compound_code_str <- as.character(data$compound_code)
# Convert compound_code_str back to numeric (long)
data$compound_code <- as.numeric(data$compound_code_str)
# Save changes
saveRDS(data, "/Users/gaelk.bertrand/Desktop/UCB/clean_data/combined_data.RData")

# Merge accordingly
# Load the main dataset
data <- readRDS("/Users/gaelk.bertrand/Desktop/UCB/clean_data/combined_data.RData")
# Load the using dataset or secondary data
nearest_property <- readRDS("/Users/gaelk.bertrand/Desktop/UCB/clean_data/nearest_property.RData")
# Merge the datasets based on compound_code
merged_data <- merge(data, nearest_property, by = "compound_code", all.x = TRUE)
# Save the merged dataset
saveRDS(merged_data, "/Users/gaelk.bertrand/Desktop/UCB/clean_data/merged_data.RData")

# Q4.Imputing missing values of number of visits post carto using polygon average
# Load the merged data
merged_data <- readRDS("/Users/gaelk.bertrand/Desktop/UCB/clean_data/merged_data.RData")

# Identify the right variable corresponding to 'number of visits post carto'
visit_carto_vars <- grep("visit|carto", names(merged_data), value = TRUE)

# Display labels of variables containing keywords related to visits and carto
str(merged_data[visit_carto_vars])

# Q4. Imputing missing values of number of visits post carto using polygon average
# Calculate average number of visits post carto for each polygon
polygon_avg <- ave(merged_data$nb_visit_post_carto, merged_data$a7, FUN = function(x) mean(x, na.rm = TRUE))

# Impute missing values of nb_visit_post_carto using the polygon average
merged_data$nb_visit_post_carto[is.na(merged_data$nb_visit_post_carto)] <- polygon_avg[is.na(merged_data$nb_visit_post_carto)]

# If not all missing values are not imputed, you can proceed with the following:
# Calculate the global average for nb_visit_post_carto
global_avg <- mean(merged_data$nb_visit_post_carto, na.rm = TRUE)

# Impute remaining missing values of nb_visit_post_carto using the global average
merged_data$nb_visit_post_carto[is.na(merged_data$nb_visit_post_carto)] <- global_avg

# Save the merged dataset
saveRDS(merged_data, "/Users/gaelk.bertrand/Desktop/UCB/clean_data/merged_data.RData")

# Q5. Generating the log version of the variable "rate"
# Find which type is the variable 'rate'
str(merged_data$rate)

# Convert the string variable "rate" to numeric
merged_data$rate <- as.numeric(merged_data$rate)

# Generate the log version of the numeric variable
merged_data$log_rate <- log(merged_data$rate)

# Save the merged dataset
saveRDS(merged_data, "/Users/gaelk.bertrand/Desktop/UCB/clean_data/merged_data.RData")

# Q6. Dummy variables for percentage of tax rate to be paid
# Generate dummy variables for reduction_pct
merged_data <- within(merged_data, {
  pct50 <- ifelse(reduction_pct == 1, 1, 0)
  pct67 <- ifelse(reduction_pct == 2, 1, 0)
  pct83 <- ifelse(reduction_pct == 3, 1, 0)
  pct100 <- ifelse(reduction_pct == 4, 1, 0)
})

# Save the new dataset
saveRDS(merged_data, "/Users/gaelk.bertrand/Desktop/UCB/clean_data/merged_draft.RData")

# Q7. Plots for the subset of those that paid taxes, by tax reduction percentages
# Subset the data to those that paid taxes
merged_data <- merged_data[merged_data$taxes_paid == 1,]

# Generate the minimum day of tax payment for each tax reduction percentage
min_day_pct50 <- min(merged_data$taxes_paid_0d[merged_data$pct50 == 1]/merged_data$taxes_paid_30d[merged_data$pct50 == 1])
min_day_pct67 <- min(merged_data$taxes_paid_0d[merged_data$pct67 == 1]/merged_data$taxes_paid_30d[merged_data$pct67 == 1])
min_day_pct83 <- min(merged_data$taxes_paid_0d[merged_data$pct83 == 1]/merged_data$taxes_paid_30d[merged_data$pct83 == 1])
min_day_pct100 <- min(merged_data$taxes_paid_0d[merged_data$pct100 == 1]/merged_data$taxes_paid_30d[merged_data$pct100 == 1])

# Plot the minimum day of tax payment for each tax reduction percentage
hist(min_day_pct50, main="50% Reduction", xlab="Day of Tax Payment", freq=TRUE)
hist(min_day_pct67, main="33% Reduction", xlab="Day of Tax Payment", freq=TRUE)
hist(min_day_pct83, main="17% Reduction", xlab="Day of Tax Payment", freq=TRUE)
hist(min_day_pct100, main="0% Reduction", xlab="Day of Tax Payment", freq=TRUE)

# Save the new dataset
saveRDS(merged_data, "/Users/gaelk.bertrand/Desktop/UCB/clean_data/merged_data.RData")

# Q8. Average taxes paid amount
# Calculate the total number of compounds and the number of compounds that paid taxes for each polygon
total_compounds <- ave(merged_data$taxes_paid, merged_data$a7, FUN = length)
total_paid_taxes <- ave(merged_data$taxes_paid, merged_data$a7, FUN = sum)

# Calculate the percentage of compounds that paid taxes for each polygon
pct_paid_taxes <- total_paid_taxes / total_compounds

# Subset the data to polygons where over 5% of the compounds paid taxes
merged_data <- merged_data[pct_paid_taxes > 0.05,]

# Calculate the average taxes paid amount
avg_taxes_paid_amt <- mean(merged_data$taxes_paid_amt, na.rm = TRUE)

# Display the average taxes paid amount rounded to three decimal places
cat("The average taxes paid amount for all observations in polygons where over 5% of the compounds paid taxes is ", round(avg_taxes_paid_amt, 3), "\n")

# Clean up
merged_data$total_compounds <- NULL
merged_data$total_paid_taxes <- NULL
merged_data$pct_paid_taxes <- NULL

# Save the new dataset
saveRDS(merged_data, "/Users/gaelk.bertrand/Desktop/UCB/clean_data/merged_data.RData")

# Load data
merged_data <- readRDS("/Users/gaelk.bertrand/Desktop/UCB/clean_data/merged_data.RData")

# Q9. BALANCE TABLES AND TESTS
# Convert necessary categorical variables to be used into binary variables first
merged_data$walls_SticksPalm <- ifelse(merged_data$walls == 1, 1, 0)
merged_data$walls_Mudbrick <- ifelse(merged_data$walls == 2, 1, 0)
merged_data$walls_BricksBadConditions <- ifelse(merged_data$walls == 3, 1, 0)
merged_data$walls_Ciment <- ifelse(merged_data$walls == 4, 1, 0)

merged_data$roof_ThatchStraw <- ifelse(merged_data$roof == 1, 1, 0)
merged_data$roof_SheetIron <- ifelse(merged_data$roof == 2, 1, 0)

# Directory assignment
outfld <- "/Users/gaelk.bertrand/Desktop/UCB/clean_data/"

# Produce the balance table using the 'tableone' package for simplicity
library(tableone)
vars <- c("dist_city_center", "dist_commune_buildings", "dist_public_schools", "dist_roads", "walls", "roof", "age_prop", "sex_prop")
tab <- CreateTableOne(vars = vars, strata = "reduction_pct", data = merged_data)
write.csv(tab, paste0(outfld, "/balance.csv"))

# Q10. REGRESSIONS
# Run regression for all properties
model_all <- lm(visit_post_carto ~ pct50 + pct67 + pct83, data = merged_data)

# Export regression results for all properties
library(broom)
tidy(model_all) %>% write.csv(paste0(outfld, "/regression_results_q10.csv"), row.names = FALSE)

# Subset data for properties with constant bonus
data_const_bonus <- subset(merged_data, bonus_constant == 1)

# Run regression for properties with constant bonus
model_const_bonus <- lm(visit_post_carto ~ pct50 + pct67 + pct83, data = data_const_bonus)

# Append regression results for properties with constant bonus to the same file
tidy(model_const_bonus) %>% write.csv(paste0(outfld, "/regression_results_q10.csv"), row.names = FALSE, append = TRUE)

# Subset data for properties with proportional bonus
data_prop_bonus <- subset(merged_data, bonus_prop == 1)

# Run regression for properties with proportional bonus
model_prop_bonus <- lm(visit_post_carto ~ pct50 + pct67 + pct83, data = data_prop_bonus)

# Append regression results for properties with proportional bonus to the same file
tidy(model_prop_bonus) %>% write.csv(paste0(outfld, "/regression_results_q10.csv"), row.names = FALSE, append = TRUE)

# Q11. REGRESSIONS
# Load data again
merged_data <- readRDS("/Users/gaelk.bertrand/Desktop/UCB/clean_data/merged_data.RData")
xlist <- c("pct50", "pct67", "pct83")

# Run regression for all properties with polygon fixed effects
model_all <- plm(visit_post_carto ~ pct50 + pct67 + pct83, data = merged_data, index = "a7", model = "within")

# Subset data for properties with constant bonus
data_const_bonus <- subset(merged_data, bonus_constant == 1)

# Run regression for properties with constant bonus with polygon fixed effects
model_const_bonus <- plm(visit_post_carto ~ pct50 + pct67 + pct83, data = data_const_bonus, index = "a7", model = "within")

# Subset data for properties with proportional bonus
data_prop_bonus <- subset(merged_data, bonus_prop == 1)

# Run regression for properties with proportional bonus with polygon fixed effects
model_prop_bonus <- plm(visit_post_carto ~ pct50 + pct67 + pct83, data = data_prop_bonus, index = "a7", model = "within")

# Q12. REGRESSIONS
# Load data again
merged_data <- readRDS("/Users/gaelk.bertrand/Desktop/UCB/clean_data/merged_data.RData")
xlist <- c("pct50", "pct67", "pct83", "visited", "visits")

# Run regression for all properties
model_all <- lm(taxes_paid ~ pct50 + pct67 + pct83 + visited + visits, data = merged_data)

# Check for multicollinearity
vif(model_all)

# Run regression for all properties to attempt to fix multicollinearity
model_all <- plm(taxes_paid ~ pct50 + pct67 + pct83 + visited + visits, data = merged_data, index = "a7", model = "within")

# Export regression results for all properties
tidy(model_all) %>% write.csv(paste0(outfld, "/regression_results_q12.csv"), row.names = FALSE)

# Subset data for properties with constant bonus
data_const_bonus <- subset(merged_data, bonus_constant == 1)

# Run regression for properties with constant bonus
model_const_bonus <- plm(taxes_paid ~ pct50 + pct67 + pct83 + visited + visits, data = data_const_bonus, index = "a7", model = "within")

# Append regression results for properties with constant bonus
tidy(model_const_bonus) %>% write.csv(paste0(outfld, "/regression_results_q12.csv"), row.names = FALSE, append = TRUE)

# Subset data for properties with proportional bonus
data_prop_bonus <- subset(merged_data, bonus_prop == 1)

# Run regression for properties with proportional bonus
model_prop_bonus <- plm(taxes_paid ~ pct50 + pct67 + pct83 + visited + visits, data = data_prop_bonus, index = "a7", model = "within")

# Append regression results for properties with proportional bonus
tidy(model_prop_bonus) %>% write.csv(paste0(outfld, "/regression_results_q12.csv"), row.names = FALSE, append = TRUE)

# Stop logging and close the log file
sink()
