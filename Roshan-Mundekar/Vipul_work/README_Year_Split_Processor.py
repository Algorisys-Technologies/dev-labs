import pandas as pd
import sys
import datetime
import os
import warnings
import re  # Importing the 're' module for regular expressions
warnings.filterwarnings('ignore')

def log_error(message):
    # Get the current date and time
    current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    # Format the message with the timestamp
    full_message = f"[{current_time}] {message}"
    
    # Write the message to the error log
    error_log_path = "error_log.txt"
    with open(error_log_path, "a") as error_log:
        error_log.write(full_message + "\n")

def process_excel(file_path, output_path):
    try:
        print('Parsing txt from excel...')
        # Load the Excel file
        excel_data = pd.ExcelFile(file_path)
        
        # Use regex to match sheet names that follow the pattern "Year Split" (e.g., "2025 Split")
        sheet_pattern = r'^\d{4} Split$'  # Regex pattern to match sheet names like "2025 Split"
        sheets = [sheet for sheet in excel_data.sheet_names if re.match(sheet_pattern, sheet)]

        columns = ['Product Link', 'Year', 'Table', 'GIS', 'GS', 'Disc.', 'PA', 'RD&A', 'NS',' ', 'Disc.', 'PA', 'RD&A', 'TOT BTL']
        ansDF = pd.DataFrame(columns=['Product Link', 'Year', 'Table', 'GIS', 'GS', 'Disc.', 'PA', 'RD&A', 'NS',' ', 'Disc.', 'PA', 'RD&A', 'TOT BTL'])

        for sheet in sheets:
            try:
                if sheet not in excel_data.sheet_names:
                    log_error(f"Sheet '{sheet}' not found in file.")
                    continue
                df = excel_data.parse(sheet)
                # print(df)
                product_link_column = df.columns[(df.iloc[1] == 'Product Link').to_numpy()]
                if product_link_column.empty:
                    log_error(f"No 'Product Link' column found in sheet: {sheet}")
                    continue
                
                if not product_link_column.empty:
                    # Extract the column name
                    column_name = product_link_column[0]

                    # Get all entries in the identified column
                    prod_link = df.loc[2:, column_name].dropna().tolist()
                    prod_link.append('Total')

                    # Extract the row 
                    selected_row = df.iloc[0].dropna()

                    if selected_row.empty:
                        log_error(f"Measures row (row 6) is empty in sheet: {sheet}")
                        continue
                    
                    for index, measure in selected_row.items():
                        start_col_index = df.columns.get_loc(index)  # Adjust for the proper column starting position
                        end_col_index = start_col_index + 11
                        measure_str = str(measure)
                        if measure_str == "Jan'23 to Feb'24 Base" or measure_str == "Jan'22 to Jan'23 Base":
                            continue
                        if start_col_index < len(df.columns) and end_col_index <= len(df.columns):
                            export_row_index = df.loc[df[column_name] == 'Export'].index[0] if 'Export' in df[column_name].values else len(df)

                            # Adjust the range dynamically based on 'Export'
                            data = df.iloc[2:export_row_index + 1, start_col_index:end_col_index].fillna(0)

                            for prod, prod_vals in zip(prod_link, data.values):
                                # Build the new row
                                new_row = [prod, sheet[:4], measure_str]
                                for val in prod_vals:
                                    new_row.append(val)
                                new_row_df = pd.DataFrame([new_row], columns=columns)
                                # Append the row to the result DataFrame
                                ansDF = pd.concat([ansDF, new_row_df], ignore_index=True)
            except Exception as sheet_error:
                log_error(f"Error processing sheet '{sheet}': {sheet_error}")

        ansDF.drop(ansDF.columns[9], axis=1, inplace=True)
        output_file_txt = output_path
        try:
            ansDF.to_csv(output_file_txt, sep='\t', index=False)
            print(f"Tab-delimited text file saved successfully at {output_file_txt}.")
        except Exception as e:
            log_error(e)
            print(f"Error saving file: {e}")

    except Exception as e:
        # Log any general errors
        with open('error_log.txt', 'a') as err_file:
            err_file.write(f"Error processing file '{file_path}': {e}")

if __name__ == "__main__":
    # Read command-line arguments
    if len(sys.argv) != 3:
        log_error("Usage: python app.py <input_file_name> <output_file_name>")
        sys.exit(1)

    # Extract input and output file names
    input_file_name = sys.argv[1]
    output_file_name = sys.argv[2]
    # Append .xlsx extension to input file name if no extension is provided
    if not input_file_name.endswith(".xlsx") and not input_file_name.endswith(".xls"):
        input_file_name += ".xlsx"

    if not output_file_name.endswith(".txt"):
        output_file_name += ".txt"

    # Append model_upload folder to input and output file paths
    model_upload_dir = "model_upload"
    input_path = os.path.join(model_upload_dir, input_file_name)
    output_path = os.path.join(model_upload_dir, output_file_name)
    # Check if input file exists
    if not os.path.exists(input_path):
        log_error(f"Error: Input file '{input_path}' does not exist.")
        sys.exit(1)

    # Process the Excel file
    process_excel(input_path, output_path)
