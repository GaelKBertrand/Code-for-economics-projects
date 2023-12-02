# Facebook Ad Campaign Analysis

## Overview

This project simulates and analyzes data from a Facebook ad campaign experiment. The simulation involves generating baseline survey data, random assignment data, and endline survey data for participants. The analysis phase evaluates the effectiveness of different ad types and includes various tables and figures for a comprehensive understanding.

## Dependencies

- Python 3
- Libraries: pandas, numpy, matplotlib, seaborn

## Running the Pipeline

### Google Colab (Recommended)

1. Open the provided collab .ipynb file (`azCollab_Bertrand_Kwibuka_Urbana_Champaign_Data_Task.ipynb`) in Google Colab.
2. Execute each cell step-by-step in the given order.

### Local Environment
#### Modifying Google Drive Paths

- In both Python scripts, update the Google Drive paths to your preferred locations.

#### Note

- For local runs, ensure you have Python 3 installed and install the necessary dependencies using:
  ```bash
  pip install pandas numpy matplotlib seaborn

#### Local implementation 

1. **Data Simulation:**
   - Run the `data_simulation.py` script after modifying the 'google drive' part.
     ```bash
     python data_simulation.py
     ```

2. **Analysis and Reporting:**
   - Run the `analysis_and_reporting.py` script after modifying the 'google drive' part.
     ```bash
     python analysis_and_reporting.py
     ```
     
# Methodologies used 

## Data Simulation Logic

The data simulation is carried out in the `data_simulation.py` script and involves the following steps:

### Baseline Survey Data Generation

- Generate participant IDs, age, gender, location, education, COVID awareness level, and other baseline survey attributes for a specified number of participants.
- Save the simulated baseline survey data to a CSV file.

### Random Assignment Data Generation

- Generate participant IDs, ad types, and feelings about information on social media for the same set of participants.
- Save the simulated random assignment data to a CSV file.

### Endline Survey Data Generation

- Simulate changes in responses based on ad type for a subset of participants who took part in the endline survey.
- Generate new attributes such as received vaccine, influenced decision, and effectiveness of ads.
- Save the simulated endline survey data to a CSV file.

## Analysis and Reporting Logic

The analysis and reporting are performed in the `analysis_and_reporting.py` script and Jupyter notebooks (`analysis_and_reporting.ipynb` and `data_simulation.ipynb`). The logic involves:

### Data Merging

- Merge the simulated datasets (baseline, random assignment, and endline survey data) based on participant IDs.

### Descriptive Analysis

- Create tables and figures to provide an overview of participant counts, effectiveness of each ad type, and demographic analyses.

### Data Visualization

- Use seaborn and matplotlib for data visualization, including bar plots, count plots, and box plots, to represent the distribution and relationships in the data.

### Statistical Analysis

- Employ statistical measures and analyses to quantify the effectiveness of each ad type, such as proportions of participants who received the vaccine and the influence of ads on vaccination decisions.


## Results

After simulating the data and conducting a comprehensive analysis of the Facebook ad campaign experiment, the following key results were obtained. You may find my instance output figures and plots in the results folder. 

### Effectiveness of Ad Types

1. **Proportion of Participants Receiving the Vaccine:**
   - The analysis revealed variations in the effectiveness of different ad types in influencing participants to receive the vaccine. The bar plot 'Proportion of Participants Who Received the Vaccine in Each Group' illustrates these differences.

2. **Influence on Decision to Get Vaccinated:**
   - Count plots were used to visualize the influence of each ad type on the decision to get vaccinated. The results highlight the varying impact of different ad types on participants' decisions.

### Demographic Analysis

1. **Age Distribution:**
   - Box plots were utilized to analyze the age distribution among different ad groups. These plots provide insights into potential age-related trends in participants' responses to the ads.

2. **Descriptive Statistics:**
   - Descriptive statistics tables offer a summary of participant characteristics by ad type. These tables include measures such as mean, standard deviation, minimum, and maximum for different demographic variables.

### Vaccine Hesitancy

1. **Proportion of Participants with Vaccine Hesitancy:**
   - Bar plots were employed to visualize the proportion of participants with vaccine hesitancy across different ad types. This analysis helps in understanding the impact of ad content on participants' hesitancy.

### Crosstab Analysis

1. **Ad Type and Vaccine Hesitancy Crosstab:**
   - A crosstab table was created to provide a detailed breakdown of the relationship between ad types and vaccine hesitancy. This table facilitates a more granular understanding of the data.

## Conclusion

The analysis provides valuable insights into the effectiveness of different ad types in influencing participants' vaccination decisions. The variations observed in participant responses across demographic groups contribute to a nuanced understanding of the campaign's impact. These results can inform future ad campaign strategies and highlight areas for further investigation.

## Acknowledgments

The simulation and analysis code was developed for a data task, following best practices for data generation and analysis. The project is designed for educational purposes, providing insights into experimental data simulation and analysis techniques.
