Facebook Ad Campaign Analysis
=============================

Overview
--------

In this project, I simulated and analyzed data from a Facebook ad campaign experiment. The simulation involved generating baseline survey data, random assignment data, and endline survey data for participants. Throughout the analysis, I evaluated the effectiveness of different ad types, presenting various tables and figures for a comprehensive understanding.

Dependencies
------------

-   [pandas](https://pandas.pydata.org/): A powerful data manipulation library.
-   [seaborn](https://seaborn.pydatax.org/): A statistical data visualization library.
-   [matplotlib](https://matplotlib.org/): A comprehensive library for creating static, animated, and interactive visualizations.
-   [scipy](https://www.scipy.org/): A library for scientific and technical computing.
-   [statsmodels](https://www.statsmodels.org/stable/index.html): A library for estimating and testing statistical models.
-   [scikit-learn](https://scikit-learn.org/): A machine learning library for classical machine learning algorithms.
-   [numpy](https://numpy.org/): A fundamental package for scientific computing with Python.

Running the Pipeline
--------------------

### Google Colab (Recommended)

1.  Open the provided Colab .ipynb file (`Bertrand_Kwibuka_Urbana_Champaign_Data_Task.ipynb`) in Google Colab.
2.  Execute each cell step-by-step in the given order.

### Local Environment

#### Modifying Google Drive Paths

-   In both Python scripts, update the Google Drive paths to your preferred locations.

#### Note

-   For local runs, ensure you have installed all the necessary dependencies.

#### Local Implementation

1.  Data Simulation:

    -   Run the `data_simulation.py` script after modifying the 'Google Drive' part.

        bashCopy code

        `python data_simulation.py`

2.  Analysis and Reporting:

    -   Run the `analysis_and_reporting.py` script after modifying the 'Google Drive' part.

        bashCopy code

        `python analysis_and_reporting.py`

Methodologies Used
==================

Data Simulation Logic
---------------------

I implemented the data simulation in the `data_simulation.py` script and followed these steps:

### Baseline Survey Data Generation

-   Generated participant IDs, age, gender, location, education, COVID awareness level, and other baseline survey attributes for a specified number of participants.
-   Saved the simulated baseline survey data to a CSV file.

### Random Assignment Data Generation

-   Generated participant IDs, ad types, and feelings about information on social media for the same set of participants.
-   Saved the simulated random assignment data to a CSV file.

### Endline Survey Data Generation

-   Simulated changes in responses based on ad type for a subset of participants who took part in the endline survey.
-   Generated new attributes such as received vaccine, influenced decision, and effectiveness of ads.
-   Saved the simulated endline survey data to a CSV file.

Analysis and Reporting Logic
----------------------------

I conducted the analysis and reporting in the `analysis_and_reporting.py` script and Jupyter notebooks (`analysis_and_reporting.ipynb` and `data_simulation.ipynb`). The logic involved:

### Data Merging

-   Merged the simulated datasets (baseline, random assignment, and endline survey data) based on participant IDs.

### Descriptive Analysis

-   Created tables and figures to provide an overview of participant counts, effectiveness of each ad type, and demographic analyses.

### Data Visualization

-   Used seaborn and matplotlib for data visualization, including bar plots, count plots, and box plots, to represent the distribution and relationships in the data.

### Statistical Analysis

-   Used statistical measures and analyses to quantify the effectiveness of each ad type, such as proportions of participants who received the vaccine and the influence of ads on vaccination decisions.

#### Statistical Tests and Modeling

I conducted the following statistical tests to assess the effectiveness of different Facebook ad campaigns in increasing COVID-19 vaccine uptake:

1.  T-test for Vaccine Uptake Rates:

    -   Purpose: Compare vaccine uptake rates between the Reason and Control groups.
    -   Key Finding: Investigated the significance of differences in vaccine uptake rates.
2.  Chi-square Test for Independence:

    -   Purpose: Analyze the independence between Emotions Ad and Vaccine Uptake.
    -   Key Finding: Assessed if there is a significant association between the Emotions Ad and vaccine uptake.
3.  Logistic Regression for Binary Outcome:

    -   Purpose: Model the binary outcome of vaccine uptake using logistic regression.
    -   Key Finding: Explored the relationship between demographic factors and the likelihood of vaccine uptake.
4.  Correlation Coefficient:

    -   Purpose: Calculate the correlation coefficient between Age and Vaccine Hesitancy.
    -   Key Finding: Examined the strength and direction of the relationship between age and vaccine hesitancy.
5.  Practical Significance Context:

    -   Determine the statistically significance difference in vaccine uptake. Considering practical significance (calculate P values), the observed differences may not be practically significant, as indicated by the effect size.


Results & Observations: Effectiveness of Ad Types
-------------------------------------------------

After simulating the data and conducting a comprehensive analysis of the Facebook ad campaign experiment, I calculated the following key tests and graphs. You may find my instance output figures and plots in the .ipynb file (`Bertrand_Kwibuka_Urbana_Champaign_Data_Task.ipynb`).

1.  Proportion of Participants Receiving the Vaccine:

    -   The analysis revealed variations in the effectiveness of different ad types in influencing participants to receive the vaccine. The bar plot 'Proportion of Participants Who Received the Vaccine in Each Group' illustrates these differences.
2.  Influence on Decision to Get Vaccinated:

    -   Count plots were used to visualize the influence of each ad type on the decision to get vaccinated. The results highlight the varying impact of different ad types on participants' decisions.

### Demographic Analysis

1.  Age Distribution:

    -   Box plots were utilized to analyze the age distribution among different ad groups. These plots provide insights into potential age-related trends in participants' responses to the ads.
2.  Descriptive Statistics:

    -   Descriptive statistics tables offer a summary of participant characteristics by ad type. These tables include measures such as mean, standard deviation, minimum, and maximum for different demographic variables.

### Vaccine Hesitancy

1.  Proportion of Participants with Vaccine Hesitancy:
    -   Bar plots were used to visualize the proportion of participants with vaccine hesitancy across different ad types. This analysis helps in understanding the impact of ad content on participants' hesitancy.

### Crosstab Analysis

1.  Ad Type and Vaccine Hesitancy Crosstab:
    -   A crosstab table was created to provide a detailed breakdown of the relationship between ad types and vaccine hesitancy. This table facilitates a more granular understanding of the data.


Acknowledgments
---------------

I developed the simulation and analysis code for a data task, following best practices for data generation and analysis. This project is designed for educational purposes, providing insights into experimental data simulation and analysis techniques.