import pandas as pd

df = pd.read_csv('../data/EmployeeDataset.csv')

print("Data shape:", df.shape)
print("\nMissing values:")
print(df.isnull().sum())

print("\nEducation levels:")
print(df['education_level'].value_counts(dropna=False))

print("\nLocations:")
print(df['location'].value_counts(dropna=False))

print("\nExperience Years:")
print(df['experience_years'].unique())

print("\nSample dates:")
print(df['date_of_marriage'].head(10))

print("\nSalaries:")
print(df['salary'].describe())
