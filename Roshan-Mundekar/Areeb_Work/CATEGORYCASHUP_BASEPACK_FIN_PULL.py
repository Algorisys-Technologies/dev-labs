import time
import pandas as pd
from TM1py import TM1Service
import sys
import logging

# ===============================
# Setup Logging
# ===============================
log_filename = f"script_log_{time.strftime('%Y%m%d_%H%M%S')}.log"
logging.basicConfig(
    filename=log_filename,
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
console = logging.StreamHandler()
console.setLevel(logging.INFO)
formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
console.setFormatter(formatter)
logging.getLogger('').addHandler(console)

# ===============================
# TM1 connection details
# ===============================
base_url='https://huldev01.planning-analytics.ibmcloud.com/tm1/api/HUL_HCPC_New/'
user="huldev0101_tm1_automation"
namespace="LDAP"
password="60527g1dCsHh"
ssl=True
verify=True
async_requests_mode=True

# ===============================
# Initialize TM1 Service
# ===============================
try:
    tm1 = TM1Service(
        base_url=base_url,
        user=user,
        namespace=namespace,
        password=password,
        ssl=ssl,
        verify=verify,
        async_requests_mode=async_requests_mode
    )
    server_name = tm1.server.get_server_name()
    logging.info("Connection to TM1 established! Server name: %s", server_name)
except Exception as e:
    logging.error("Failed to connect to TM1: %s", e)
    sys.exit(1)

# ===============================
# Execute MDX
# ===============================
mdx_source = """
SELECT 
   {
      TM1SubsetToSet([Month].[Month], "Forecast_Months", "public")       
   } *
   {
      TM1SubsetToSet([Basepack_Final].[Basepack_Final], "N_Level", "public")
   } *
   {
      TM1FilterByLevel(TM1SubsetAll([Channels].[Channels]), 1)
   } ON 0, 
   {
      TM1SubsetToSet([Cashup_m].[Cashup_m], "Trading_Trends", "public")
   } ON 1
FROM [Category_cashup]
WHERE (
   [Data_Source].[Data_Source].[Trading Trend],
   [Version].[Version].[CV], 
   [State].[State].[All India],
   [Elist].[Elist].[Elist],
   [Year].[Year].[Current_Year]
)
"""

try:
    start_time = time.time()
    logging.info("Starting MDX Execution ...")
    df = tm1.cubes.cells.execute_mdx_dataframe(mdx_source)
    run_time = time.time() - start_time
    logging.info("MDX Execution complete. Time taken: %.2f seconds", run_time)
except Exception as e:
    logging.error("Error during MDX Execution: %s", e)
    sys.exit(1)

# ===============================
# Rename columns and Pivot
# ===============================
try:
    df.columns = ['Cashup_M', 'Month', 'Basepack_Final', 'Channels', 'Value']
    pivot_df = df.pivot_table(
        index=['Month', 'Basepack_Final', 'Channels'],
        columns='Cashup_M',
        values='Value',
        fill_value=0
    ).reset_index()
    logging.info("Pivot table created successfully.")
except Exception as e:
    logging.error("Error during pivot table creation: %s", e)
    sys.exit(1)

# ===============================
# Export to CSV
# ===============================
try:
    start_time = time.time()
    logging.info("Starting export to CSV...")

    # Reset index to convert all index levels to columns
    pivot_df = pivot_df.reset_index()

    # Remove the first column (integer index column)
    pivot_df = pivot_df.iloc[:, 1:]

    # Rename the new first column to 'Month'
    new_columns = list(pivot_df.columns)
    new_columns[0] = 'Month'
    pivot_df.columns = new_columns

    # Write to CSV with encoding and 8 empty lines
    with open("BasepackxChannel_Automation_TrT_&_BP_Fin.csv", "w", newline='', encoding='utf-8-sig') as f:
        for _ in range(8):
            f.write("\n")
        pivot_df.to_csv(f, index=False)

    run_time = time.time() - start_time
    logging.info("CSV export complete. Time taken: %.2f seconds", run_time)
except Exception as e:
    logging.error("Error during CSV export: %s", e)
    sys.exit(1)

logging.info("Script completed successfully. Log file: %s", log_filename)
