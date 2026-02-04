import sys
import pandas as pd
import os
import warnings 

def process_excel(file_path,output_path):
    try : 
        print("Parsing txt file...")
        # Path to the Excel file
        # file_path = "a.xlsx"
        # Suppress warnings
        warnings.simplefilter("ignore")

        # Load the Excel file
        excel_data = pd.ExcelFile(file_path)

        # Sheets to process only
        sheets = ['GT', 'MT', 'Ecom', 'CSD', 'Insti', '3P', 'Export']

        # Initialize the result DataFrame with required columns
        ansDF = pd.DataFrame(columns=['SKU', 'Sheet', 'Measure', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'])

        error_log_path = 'error_log.txt'
        # Iterate over the sheets to process
        for sheet_name in sheets:
            try : 
                # Parse the selected sheet
                if sheet_name not in excel_data.sheet_names:
                    with open(error_log_path, 'a') as err_file:
                        err_file.write(f"Sheet '{sheet_name}' not found in file.\n")
                    continue
                # Parse the selected sheet
                df = excel_data.parse(sheet_name)
                
                # Find the column where row 7 has "Pack Link"
                pack_link_column = df.columns[(df.iloc[7] == 'Pack Link').to_numpy()]

                if pack_link_column.empty:
                    with open(error_log_path, 'a') as err_file:
                        err_file.write(f"No 'Pack Link' column found in sheet: {sheet_name}\n")
                    continue

                if not pack_link_column.empty:
                    # Extract the column name
                    column_name = pack_link_column[0]
                    
                    # Get all entries in the identified column starting from row 8 to row 108 (0-based index)
                    skus = []
                    for value in df.loc[8:, column_name].dropna():
                        if value == 'Export':
                            skus.append(value)
                            break
                        skus.append(value)
                    endIndex = len(skus)
                    # Extract the row containing measures (row 6 in your example)
                    selected_row = df.iloc[6].dropna()

                    if selected_row.empty:
                        with open(error_log_path, 'a') as err_file:
                            err_file.write(f"Measures row (row 6) is empty in sheet: {sheet_name}\n")
                        continue
                    
                    # Extract the month names from row 7 (e.g., "Jan'23", "Feb'23", etc.)
                    month_names = []
                    for col in df.iloc[7].dropna():
                        if isinstance(col, str):  # Check if the value is a string
                            # Extract the month part (e.g., "Jan" from "Jan'23")
                            month_name = col.split("'")[0]
                            month_names.append(month_name)
                        else:
                            month_names.append('')  # Append an empty string for non-string values

                    # Ensure that the month names cover from Jan to Dec
                    month_dict = dict(zip(month_names, ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']))

                    # Define column ranges dynamically for each measure
                    for index, measure in selected_row.items():
                        if pd.notna(measure):
                            # Ensure measure is a string before calling `startswith`
                            measure_str = str(measure)

                            # For "Actual" measure, map to months Jan to Jul
                            if measure_str.startswith('Actual'):
                                start_col_index = df.columns.get_loc(index)  # Adjust for the proper column starting position
                                end_col_index = start_col_index + 7  # Actual months (Jan to Jul)

                                # Extract actual month data (Jan to Jul)
                                if start_col_index < len(df.columns) and end_col_index <= len(df.columns):
                                    month_data = df.iloc[8:endIndex+8, start_col_index:end_col_index].fillna(0)

                                    # Build rows for ansDF for "Actual"
                                    for sku, month_vals in zip(skus, month_data.values):
                                        # Create a dictionary for the month values (Jan to Jul only)
                                        month_dict_row = dict(zip(['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'], month_vals))
                                        
                                        # Add NaN or 0 for the remaining months (Aug to Dec)
                                        month_dict_row.update({'Aug': 0, 'Sep': 0, 'Oct': 0, 'Nov': 0, 'Dec': 0})

                                        # Build the new row
                                        new_row = {
                                            'SKU': sku,
                                            'Sheet': sheet_name,
                                            'Measure': measure_str,
                                            **month_dict_row
                                        }

                                        # Append the row to the result DataFrame
                                        ansDF = pd.concat([ansDF, pd.DataFrame([new_row])], ignore_index=True)

                            # For "BE" measure, map to months Aug to Dec
                            elif measure_str.startswith('BE'):
                                start_col_index = df.columns.get_loc(index)  # Adjust for the proper column starting position
                                end_col_index = start_col_index + 5  # BE months (Aug to Dec)

                                # Extract BE month data (Aug to Dec)
                                if start_col_index < len(df.columns) and end_col_index <= len(df.columns):
                                    month_data = df.iloc[8:endIndex+8, start_col_index:end_col_index].fillna(0)

                                    # Build rows for ansDF for "BE"
                                    for sku, month_vals in zip(skus, month_data.values):
                                        # Create a dictionary for the month values (Aug to Dec only)
                                        month_dict_row = dict(zip(['Aug', 'Sep', 'Oct', 'Nov', 'Dec'], month_vals))
                                        
                                        # Add NaN or 0 for the remaining months (Jan to Jul)
                                        month_dict_row.update({'Jan': 0, 'Feb': 0, 'Mar': 0, 'Apr': 0, 'May': 0, 'Jun': 0, 'Jul': 0})

                                        # Build the new row
                                        new_row = {
                                            'SKU': sku,
                                            'Sheet': sheet_name,
                                            'Measure': measure_str,
                                            **month_dict_row
                                        }

                                        # Append the row to the result DataFrame
                                        ansDF = pd.concat([ansDF, pd.DataFrame([new_row])], ignore_index=True)

                            # For other measures (not "Actual" or "BE"), map to months Jan to Dec
                            else:
                                start_col_index = df.columns.get_loc(index)  # Adjust for the proper column starting position
                                end_col_index = start_col_index + 12  # All months (Jan to Dec)

                                # Extract month data (Jan to Dec)
                                if start_col_index < len(df.columns) and end_col_index <= len(df.columns):
                                    month_data = df.iloc[8:endIndex+8, start_col_index:end_col_index].fillna(0)
                                    # Build rows for ansDF for other measures
                                    for sku, month_vals in zip(skus, month_data.values):
                                        # Create a dictionary for the month values (Jan to Dec)
                                        month_dict_row = dict(zip(['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'], month_vals))

                                        # Build the new row
                                        new_row = {
                                            'SKU': sku,
                                            'Sheet': sheet_name,
                                            'Measure': measure_str,
                                            **month_dict_row
                                        }

                                        # Append the row to the result DataFrame
                                        ansDF = pd.concat([ansDF, pd.DataFrame([new_row])], ignore_index=True)

                else:
                    print(f"No column found with 'Pack Link' in row 7 in sheet: {sheet_name}")
            except Exception as sheet_error:
                with open('error_log.txt', 'a') as err_file:
                    err_file.write(f"Error processing sheet '{sheet_name}': {sheet_error}\n") 
                    
        # Display the top rows of the result DataFrame
        # print(ansDF.head(10))

        # Save the DataFrame as a CSV file
        # output_file_csv = "output.csv"
        # ansDF.to_csv(output_file_csv, index=False)
        # print(f"CSV file saved successfully at {output_file_csv}.")
        # Save the DataFrame as a Tab-delimited text file (.txt)
        output_file_txt = output_path
        try:
            ansDF.to_csv(output_file_txt, sep='\t', index=False)
            print(f"Tab-delimited text file saved successfully at {output_file_txt}.")
        except Exception as e:
            print(f"Error saving file: {e}")
    except Exception as e:
        # Log any general errors
        with open('error_log.txt', 'a') as err_file:
            err_file.write(f"Error processing file '{file_path}': {e}\n")


def log_error(message):
    error_log_path = "error_log.txt"
    with open(error_log_path, "a") as error_log:
        error_log.write(message + "\n")

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