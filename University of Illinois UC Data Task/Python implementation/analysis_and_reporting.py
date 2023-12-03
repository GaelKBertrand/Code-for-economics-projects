# Import necessary libraries for analysis
import matplotlib.pyplot as plt
import seaborn as sns

# Load generated datasets from Google Drive
baseline_data = pd.read_csv('/content/drive/My Drive/baseline_survey_data.csv')
random_assignment_data = pd.read_csv('/content/drive/My Drive/random_assignment_data.csv')
endline_data = pd.read_csv('/content/drive/My Drive/endline_survey_data.csv')

# Merge datasets
merged_data = pd.merge(baseline_data, random_assignment_data, on='Participant_ID')
merged_data = pd.merge(merged_data, endline_data, on='Participant_ID')

# Print column names in the merged dataset
print("Column Names in Merged Dataset:", merged_data.columns)

# Convert 'Received_Vaccine' to numeric
merged_data['Received_Vaccine'] = pd.to_numeric(merged_data['Received_Vaccine'].replace({'Yes': 1, 'No': 0}))
# Convert 'Vaccine_Hesitancy_x' to numeric values
vaccine_hesitancy_mapping = {'No': 0, 'Yes': 1, 'Not Sure': 2}
merged_data['Vaccine_Hesitancy_x'] = merged_data['Vaccine_Hesitancy_x'].map(vaccine_hesitancy_mapping)



# Analysis and reporting

# Table: Count of participants in each group
table1 = pd.crosstab(merged_data['Ad_Type_x'], merged_data['Received_Vaccine'], margins=True, margins_name="Total")
table1.columns = ["Did Not Receive Vaccine", "Received Vaccine", "Total"]
print("Table 1: Count of Participants in Each Group")
print(table1)
print("\n")

# Table: Effectiveness of Reason Ad
table2 = pd.crosstab(merged_data[merged_data['Ad_Type_x'] == 'Reason']['Effectiveness_Reason_Ad'],
                    merged_data[merged_data['Ad_Type_x'] == 'Reason']['Received_Vaccine'],
                    margins=True, margins_name="Total")
table2.columns = ["Did Not Receive Vaccine", "Received Vaccine", "Total"]
print("Table 2: Effectiveness of Reason Ad")
print(table2)
print("\n")

# Table: Effectiveness of Emotions Ad
table3 = pd.crosstab(merged_data[merged_data['Ad_Type_x'] == 'Emotions']['Effectiveness_Emotions_Ad'],
                    merged_data[merged_data['Ad_Type_x'] == 'Emotions']['Received_Vaccine'],
                    margins=True, margins_name="Total")
table3.columns = ["Did Not Receive Vaccine", "Received Vaccine", "Total"]
print("Table 3: Effectiveness of Emotions Ad")
print(table3)
print("\n")

# Figure: Proportion of participants who received the vaccine in each group
plt.figure(figsize=(10, 6))
sns.barplot(x='Ad_Type_x', y='Received_Vaccine', data=merged_data, ci=None)
plt.title('Proportion of Participants Who Received the Vaccine in Each Group')
plt.xlabel('Ad Type')
plt.ylabel('Proportion Received Vaccine')
plt.show()

# Figure: Influence on Decision to Get Vaccinated by Ad Type
plt.figure(figsize=(10, 6))
sns.countplot(x='Influenced_Decision', hue='Ad_Type_x', data=merged_data)
plt.title('Influence on Decision to Get Vaccinated by Ad Type')
plt.xlabel('Influence on Decision')
plt.ylabel('Count')
plt.legend(title='Ad Type')
plt.show()


# Demographic Analysis: Example for 'Age_x'
plt.figure(figsize=(12, 8))
sns.boxplot(x='Ad_Type_x', y='Age_x', data=merged_data)
plt.title('Demographic Analysis: Age Distribution by Ad Type')
plt.xlabel('Ad Type')
plt.ylabel('Age')
plt.show()
# You can create similar plots for other demographic variables like 'Gender_x', 'Location_x', etc.


# Table: Descriptive statistics of participants by Ad Type
table4 = merged_data.groupby('Ad_Type_x').describe().stack()
print("Table 4: Descriptive Statistics of Participants by Ad Type")
print(table4)
print("\n")

# Figure: Distribution of Ages by Ad Type
plt.figure(figsize=(10, 6))
sns.boxplot(x='Ad_Type_x', y='Age_x', data=merged_data)
plt.title('Distribution of Ages by Ad Type')
plt.xlabel('Ad Type')
plt.ylabel('Age')
plt.show()

# Table: Crosstab of Ad Type and Vaccine Hesitancy
table5 = pd.crosstab(merged_data['Ad_Type_x'], merged_data['Vaccine_Hesitancy_x'], margins=True, margins_name="Total")
table5.columns = ["Not Hesitant", "Hesitant", "Not Sure", "Total"]
print("Table 5: Crosstab of Ad Type and Vaccine Hesitancy")
print(table5)
print("\n")

# Figure: Proportion of Participants with Vaccine Hesitancy by Ad Type
plt.figure(figsize=(10, 6))
sns.barplot(x='Ad_Type_x', y='Vaccine_Hesitancy_x', data=merged_data, ci=None)
plt.title('Proportion of Participants with Vaccine Hesitancy by Ad Type')
plt.xlabel('Ad Type')
plt.ylabel('Proportion with Vaccine Hesitancy')
plt.show()


# T-test for vaccine uptake rates between Reason and Control groups
reason_group = merged_data[merged_data['Ad_Type_x'] == 'Reason']['Received_Vaccine']
control_group = merged_data[merged_data['Ad_Type_x'] == 'Control']['Received_Vaccine']
t_stat, p_value = ttest_ind(reason_group, control_group)
print(f"T-test for Vaccine Uptake Rates (Reason vs. Control): p-value = {p_value}")

# Chi-square test for independence between Emotions Ad and Vaccine Uptake
contingency_table = pd.crosstab(merged_data[merged_data['Ad_Type_x'] == 'Emotions']['Received_Vaccine'],
                                merged_data[merged_data['Ad_Type_x'] == 'Emotions']['Ad_Type_x'])
chi2_stat, chi2_p_value, _, _ = chi2_contingency(contingency_table)
print(f"Chi-square test for Independence (Emotions Ad and Vaccine Uptake): p-value = {chi2_p_value}")

# Logistic regression for binary outcome
logreg = LogisticRegression()
X = merged_data[['Age_x', 'Vaccine_Hesitancy_x']]
y = merged_data['Received_Vaccine']
logreg.fit(X, y)
logistic_p_value = logreg.score(X, y)  # This is just an example because we need to measure effectiveness, one should validate the model and form further hypotheses

print(f"Logistic Regression for Vaccine Uptake: Accuracy p-value = {logistic_p_value}")

# Correlation coefficient between Age and Vaccine Hesitancy
correlation_coefficient, corr_p_value = pointbiserialr(merged_data['Age_x'], merged_data['Vaccine_Hesitancy_x'])
print(f"Correlation Coefficient between Age and Vaccine Hesitancy: {correlation_coefficient}, p-value = {corr_p_value}")

# Effect size for T-test
effect_size = sm.stats.proportion_effectsize(reason_group.mean(), control_group.mean())
print(f"Effect Size (Cohen's d) for T-test: {effect_size}")

# Practical Significance Context
if p_value < 0.05:
    print("Statistically significant difference observed.")
    if effect_size > 0.2:
        print("The observed difference is also practically significant.")
    else:
        print("The observed difference may not be practically significant.")
else:
    print("No statistically significant difference observed.")



