# Mount Google Drive
from google.colab import drive

drive.mount('/content/drive')

# Set random seed for reproducibility
np.random.seed(42)


# Function to generate baseline survey data
def generate_baseline_survey_data(num_participants):
    data = {
        'Participant_ID': list(range(1, num_participants + 1)),
        'Age': np.random.randint(18, 65, size=num_participants),
        'Gender': np.random.choice(['Male', 'Female'], size=num_participants),
        'Location': np.random.choice(['Urban', 'Suburban', 'Rural'], size=num_participants),
        'Education': np.random.choice(['High School', 'College', 'Graduate School'], size=num_participants),
        'COVID_Awareness_Level': np.random.choice(['Low', 'Medium', 'High'], size=num_participants),
        'Received_Info_Social_Media': np.random.choice(['Yes', 'No'], size=num_participants),
        'Vaccine_Hesitancy': np.random.choice(['Yes', 'No', 'Not Sure'], size=num_participants),
        'Reasons_For_Hesitancy': np.where(np.random.rand(num_participants) < 0.2, 'Concerns about side effects', ''),
        # Add more baseline questions as needed
    }
    baseline_data = pd.DataFrame(data)

    # Save baseline data to CSV on Google Drive
    baseline_data.to_csv('/content/drive/My Drive/baseline_survey_data.csv', index=False, quoting=2)

    return baseline_data


# Generate baseline survey data
baseline_data = generate_baseline_survey_data(5000)


# Function to generate random assignment data
def generate_random_assignment_data(num_participants):
    data = {
        'Participant_ID': list(range(1, num_participants + 1)),
        'Ad_Type': np.random.choice(['Reason', 'Emotions', 'Control'], size=num_participants),
        'Feel_About_Info_Social_Media': np.random.choice(['Positive', 'Neutral', 'Negative'], size=num_participants),
    }
    random_assignment_data = pd.DataFrame(data)

    # Save random assignment data to CSV on Google Drive
    random_assignment_data.to_csv('/content/drive/My Drive/random_assignment_data.csv', index=False, quoting=2)

    return random_assignment_data


# Generate random assignment data
random_assignment_data = generate_random_assignment_data(5000)


# Function to generate endline survey data
def generate_endline_survey_data(baseline_data, num_endline_participants):
    # Ensure the correct number of participants for endline survey
    num_baseline_participants = len(baseline_data)
    if num_endline_participants > num_baseline_participants:
        raise ValueError(
            f"num_endline_participants ({num_endline_participants}) should be less than or equal to the total number of baseline participants ({num_baseline_participants}).")

    endline_participants = np.random.choice(baseline_data['Participant_ID'], size=num_endline_participants,
                                            replace=False)

    # Simulate changes in responses based on ad type
    endline_data = baseline_data[baseline_data['Participant_ID'].isin(endline_participants)].copy()

    # Add 'Ad_Type' column to endline_data
    endline_data['Ad_Type'] = random_assignment_data['Ad_Type'].values[:num_endline_participants]

    endline_data['Received_Vaccine'] = np.random.choice(['Yes', 'No'], size=len(endline_data))
    endline_data['Influenced_Decision'] = np.where(endline_data['Received_Vaccine'] == 'Yes',
                                                   np.random.choice(['Reason Ad', 'Emotions Ad', 'Other'],
                                                                    size=len(endline_data)),
                                                   'Not Applicable')

    endline_data['Effectiveness_Reason_Ad'] = np.where(endline_data['Ad_Type'] == 'Reason',
                                                       np.random.choice(['Not at all effective', 'Somewhat effective',
                                                                         'Very effective'], size=len(endline_data)),
                                                       '')

    endline_data['Effectiveness_Emotions_Ad'] = np.where(endline_data['Ad_Type'] == 'Emotions',
                                                         np.random.choice(['Not at all effective', 'Somewhat effective',
                                                                           'Very effective'], size=len(endline_data)),
                                                         '')
    # Add more endline questions as needed

    # Save endline data to CSV on Google Drive
    endline_data.to_csv('/content/drive/My Drive/endline_survey_data.csv', index=False, quoting=2)

    return endline_data


# Generate endline survey data
endline_data = generate_endline_survey_data(baseline_data, 4500)


