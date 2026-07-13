import os
import pandas as pd

excel_path = '/mnt/c/Users/Admin/.gemini/antigravity-ide/scratch/BigDataProject/big-data-architecture/data/student_score.xlsx'
csv_output_path = '/home/ambsh/big-data-analytics-group-assignemnt/data/student_scores.csv'

try:
    # Read excel without headers
    df = pd.read_excel(excel_path, header=None)
    
    # 1. Drop column 0 (which is column A, entirely empty)
    df = df.drop(columns=[0])
    
    # 2. Drop row 0 (which is row 1 in Excel, entirely empty)
    df = df.iloc[1:].reset_index(drop=True)
    
    # 3. Now the first row (index 0) contains the headers
    headers = df.iloc[0].tolist()
    headers = [str(h).strip() for h in headers]
    
    # 4. Set headers and drop the header row
    df.columns = headers
    df = df.iloc[1:].reset_index(drop=True)
    
    # 5. Rename student_id to id
    df = df.rename(columns={'student_id': 'id'})
    
    # Clean whitespace from text columns
    for col in df.columns:
        # Convert values to strings where appropriate and strip whitespace
        df[col] = df[col].apply(lambda x: str(x).strip() if pd.notnull(x) else "")
    
    # 6. Reorder columns to: id, name, gender, marks, course
    df = df[['id', 'name', 'gender', 'marks', 'course']]
    
    print("\n--- Processed Dataframe ---")
    print(df)
    
    # Save to CSV
    os.makedirs(os.path.dirname(csv_output_path), exist_ok=True)
    df.to_csv(csv_output_path, index=False)
    print(f"\nSuccessfully converted and saved to: {csv_output_path}")
    
except Exception as e:
    print(f"Error: {e}")
