import pandas as pd
import numpy as np
import re
from datetime import datetime

def transform_excel_data(input_file_path, output_file_path):
    # Read Excel file without headers
    df_raw = pd.read_excel(input_file_path, header=None)
    
    # Clean rows - remove media pointers and empty rows
    cleaned_rows = []
    for _, row in df_raw.iterrows():
        row_str = ' '.join([str(cell) for cell in row if pd.notna(cell) and str(cell).strip() != ''])
        if not row_str.startswith('[media') and row_str.strip() != '':
            cleaned_rows.append([str(cell) if pd.notna(cell) else '' for cell in row])
    
    if not cleaned_rows:
        raise ValueError("No valid data found in the Excel file after cleaning")
    
    df_clean = pd.DataFrame(cleaned_rows)
    
    # Identify year headers from the first row
    year_row = df_clean.iloc[0].tolist()
    years = [str(cell).strip() for cell in year_row if re.match(r'20[2-9][0-9]', str(cell))][:3]
    header_years = sorted([int(year) for year in years])
    
    # Create column names structure
    base_columns = ['Category', 'PPG_code', 'SKU_name']
    total_columns = base_columns.copy()
    for year in years:
        total_columns.extend([f"{year}_Month", f"{year}_grams", f"{year}_MRP", f"{year}_PPG", f"{year}_sep"])
    total_columns.append('pct_increase')
    
    # Process data rows (starting after header rows)
    data = []
    for i in range(2, len(df_clean)):
        row = df_clean.iloc[i].tolist()
        row = [str(cell).strip() if pd.notna(cell) else '' for cell in row]
        if len(row) < len(total_columns):
            row += [''] * (len(total_columns) - len(row))
        elif len(row) > len(total_columns):
            row = row[:len(total_columns)]
        data.append(row)
    
    df = pd.DataFrame(data, columns=total_columns)
    df['orig_idx'] = df.index
    
    # Forward fill Category and PPG_code
    df[['Category', 'PPG_code']] = df[['Category', 'PPG_code']].replace('', np.nan).ffill()
    
    # Melt-like transformation to extract data
    year_dfs = []
    
    for year in years:
        month_col = f"{year}_Month"
        grams_col = f"{year}_grams"
        mrp_col = f"{year}_MRP"
        
        year_df = df[['orig_idx', 'PPG_code', month_col, grams_col, mrp_col]].copy()
        year_df.columns = ['orig_idx', 'PPG', 'Month', 'gm', 'MRP']
        
        # Handle missing Month
        year_df['Month'] = year_df['Month'].apply(lambda x: 'N/A' if str(x).strip() == '' else x)
        
        # Enhanced check for "Discontinued" - check all columns
        discontinued_pattern = r'discontinu|dicontinu'
        discontinued_mask = (
            year_df['Month'].str.contains(discontinued_pattern, case=False, na=False) |
            year_df['gm'].astype(str).str.contains(discontinued_pattern, case=False, na=False) |
            year_df['MRP'].astype(str).str.contains(discontinued_pattern, case=False, na=False)
        )
        
        # If discontinued, set all values to NaN
        year_df.loc[discontinued_mask, 'gm'] = np.nan
        year_df.loc[discontinued_mask, 'MRP'] = np.nan
        year_df.loc[discontinued_mask, 'Month'] = 'DISCONTINUED'
        
        # Handle grams and MRP
        year_df['gm'] = pd.to_numeric(year_df['gm'], errors='coerce')
        year_df['MRP'] = pd.to_numeric(year_df['MRP'], errors='coerce')
        
        # Extract month and year from string like "Jul'24"
        year_df['Month'] = year_df['Month'].apply(
            lambda x: re.sub(r"[^a-zA-Z]", "", str(x))[:3].title() if not re.match(r'^(N/A|DISCONTINUED)$', str(x)) else x
        )
        
        year_df['Year'] = int(year)
        year_dfs.append(year_df[['orig_idx', 'PPG', 'Year', 'Month', 'gm', 'MRP']])
    
    # Combine all years
    final_df = pd.concat(year_dfs, ignore_index=True)
    
    # Fill missing PPG
    final_df['PPG'] = final_df['PPG'].replace('', np.nan).ffill().fillna('UNKNOWN_PPG')
    
    # Find the first discontinued year for each PPG
    discontinued_years = {}
    for ppg in final_df['PPG'].unique():
        ppg_data = final_df[final_df['PPG'] == ppg]
        discontinued_years[ppg] = ppg_data[ppg_data['Month'] == 'DISCONTINUED']['Year'].min()
    
    # Remove all rows for years after the first discontinued year for each PPG
    for ppg, first_discontinued_year in discontinued_years.items():
        if not pd.isna(first_discontinued_year):
            final_df = final_df[~((final_df['PPG'] == ppg) & (final_df['Year'] >= first_discontinued_year))]
    
    # Remove discontinued rows
    final_df = final_df[final_df['Month'] != 'DISCONTINUED']
    
    # Standardize month names
    months_order = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
    month_mapping = {
        'Sept': 'Sep', 'September': 'Sep', 
        'October': 'Oct', 'November': 'Nov', 'December': 'Dec',
        'January': 'Jan', 'February': 'Feb', 'March': 'Mar', 
        'April': 'Apr', 'June': 'Jun', 'July': 'Jul', 'August': 'Aug'
    }
    
    final_df['Month'] = final_df['Month'].map(month_mapping).fillna(final_df['Month'])
    final_df = final_df[final_df['Month'].isin(months_order) | (final_df['Month'] == 'N/A')]
    
    # Create separate DataFrames for Grams and MRP
    grams_df = final_df[['PPG', 'Year', 'Month', 'gm']].copy()
    grams_df['Measure'] = 'Gram'
    grams_df.rename(columns={'gm': 'Value'}, inplace=True)
    
    mrp_df = final_df[['PPG', 'Year', 'Month', 'MRP']].copy()
    mrp_df['Measure'] = 'MRP'
    mrp_df.rename(columns={'MRP': 'Value'}, inplace=True)
    
    long_df = pd.concat([grams_df, mrp_df])
    
    # Handle cases where Month is N/A but Value exists
    # First, identify PPG-Year-Measure combinations with N/A month but valid values
    na_with_values = long_df[
        (long_df['Month'] == 'N/A') & 
        (long_df['Value'].notna())
    ].copy()
    
    # Remove these rows from the original long_df
    long_df = long_df[~((long_df['Month'] == 'N/A') & (long_df['Value'].notna()))]
    
    # For each PPG-Year-Measure with N/A month but valid values,
    # create entries for all months of that year
    expanded_rows = []
    for _, row in na_with_values.iterrows():
        for month in months_order:
            new_row = row.copy()
            new_row['Month'] = month
            expanded_rows.append(new_row)
    
    # Add the expanded rows to long_df
    if expanded_rows:
        expanded_df = pd.DataFrame(expanded_rows)
        long_df = pd.concat([long_df, expanded_df], ignore_index=True)
    
    # Create complete timeline grid - ensure only non-discontinued years are included
    all_ppgs = long_df['PPG'].unique()
    measures = ['Gram', 'MRP']
    
    # Create all combinations of PPG, Measure, Year, Month
    # But only include years that are not after the first discontinued year for each PPG
    grid_rows = []
    for ppg in all_ppgs:
        # Get the first discontinued year for this PPG, if any
        first_discontinued_year = discontinued_years.get(ppg, float('inf'))
        
        for measure in measures:
            for year in header_years:
                # Skip years after the first discontinued year
                if year >= first_discontinued_year:
                    continue
                    
                for month in months_order:
                    grid_rows.append([ppg, measure, year, month])
    
    grid = pd.DataFrame(grid_rows, columns=['PPG', 'Measure', 'Year', 'Month'])
    
    # Merge with actual data points
    merged = grid.merge(
        long_df, 
        on=['PPG', 'Measure', 'Year', 'Month'], 
        how='left'
    )
    
    # Convert Year to integer for sorting
    merged['Year'] = merged['Year'].astype(int)
    
    # Create month number mapping for sorting
    month_num_map = {month: i+1 for i, month in enumerate(months_order)}
    merged['month_num'] = merged['Month'].map(month_num_map)
    
    # Create a continuous timeline for proper forward-filling
    merged['date'] = pd.to_datetime(
        merged['Year'].astype(str) + '-' + merged['month_num'].astype(str) + '-01',
        format='%Y-%m-%d',
        errors='coerce'
    )
    
    # Sort chronologically within each PPG-Measure group
    merged.sort_values(['PPG', 'Measure', 'date'], inplace=True)
    
    # Forward fill values within each PPG-Measure group
    merged['Value'] = merged.groupby(['PPG', 'Measure'])['Value'].ffill()
    
    # Pivot to wide format
    pivot_df = merged.pivot_table(
        index=['PPG', 'Year', 'Measure'],
        columns='Month',
        values='Value',
        aggfunc='first'
    ).reset_index()
    
    # Ensure all months are present as columns
    for month in months_order:
        if month not in pivot_df:
            pivot_df[month] = np.nan
    
    # Reorder columns and sort
    pivot_df = pivot_df[['PPG', 'Year', 'Measure'] + months_order]
    pivot_df['Measure'] = pd.Categorical(pivot_df['Measure'], categories=['Gram', 'MRP'], ordered=True)
    pivot_df.sort_values(['PPG', 'Year', 'Measure'], inplace=True)
    
    # Fill missing values with empty string
    pivot_df[months_order] = pivot_df[months_order].fillna('')
    pivot_df.reset_index(drop=True, inplace=True)
    
    # Save to Excel
    pivot_df.to_excel(output_file_path, index=False)
    print(f"Transformation complete. Output saved to {output_file_path}")
    return pivot_df

if __name__ == "__main__":
    input_excel = "MRP_Master_Formate.xlsx"
    output_excel = "output_data.xlsx"
    transformed_data = transform_excel_data(input_excel, output_excel)