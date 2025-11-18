import os
import uuid
import logging
import re
import pymssql
import requests
from datetime import datetime
from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
from openpyxl import Workbook
from dotenv import load_dotenv

load_dotenv(override=True)

app = Flask(__name__)
CORS(app)

# Database Configuration
DB_CONFIG = {
    "server": os.getenv("DB_SERVER"),
    "user": os.getenv("DB_USER"),
    "password": os.getenv("DB_PASSWORD"),
    "database": os.getenv("DB_NAME"),
    'port': 1433
}

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

BASE_DIR = os.path.abspath(os.path.dirname(__file__))
EXCEL_DATA_PATH = os.path.join(BASE_DIR, 'static', 'ExcelData')
IMAGE_SAVE_PATH = os.path.join(BASE_DIR, 'static', 'Images')


# Ensure directories exist
os.makedirs(EXCEL_DATA_PATH, exist_ok=True)
os.makedirs(IMAGE_SAVE_PATH, exist_ok=True)

def log_event(message):
    """Log events with timestamp"""
    logger.info(f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S')} - {message}")

def process_row(row):
    """Process individual row data for database insertion"""
    try:
        unique_id = row.get('unique_id', str(uuid.uuid4()))
        current_date = row.get('current_date', datetime.now().date())
        header = row.get('page_title', '')[:500]
        product_name = row.get('product_name', '')[:500]
        image_path = row.get('image_path', '')[:1000]
        
        # Enhanced Kt extraction
        kt = extract_karat_info(row.get('product_name', ''))
        
        # Price extraction
        price = extract_price(row.get('price', ''))
        
        # Enhanced diamond weight extraction
        total_dia_wt = extract_diamond_weight(row.get('product_name', ''))
        
        additional_info = row.get('additional_info', '')[:1000] if row.get('additional_info') else None
        
        return (
            unique_id,
            current_date,
            header,
            product_name,
            image_path,
            kt,
            price,
            total_dia_wt,
            additional_info
        )
    except Exception as e:
        logger.error(f"Error processing row: {e}")
        return None



def extract_metals(text):
    """Extracts and prioritizes longest, most descriptive metal-related phrases."""
    if not text:
        return []

    text_upper = text.upper()

    patterns = [
        # Match like "9K White Gold", "14CT Rose Gold & White Gold"
        r'\b\d{1,2}(?:K|CT|CARAT)\s*(?:WHITE|YELLOW|ROSE|STRAWBERRY|TWO[- ]TONE)?\s*GOLD\b',

        # Match standalone metal names
        r'\b(?:PLATINUM|STERLING\s*SILVER|SILVER|WHITE\s*GOLD|YELLOW\s*GOLD|ROSE\s*GOLD|STRAWBERRY\s*GOLD|TWO[- ]TONE\s*GOLD|TITANIUM|BRASS|PALLADIUM|COPPER|ALLOY)\b',

        # Match just karat values like "9K", "14CT" — only if not part of a decimal
        r'(?<![\d.])\b\d{1,2}(?:K|CT|CARAT)\b'
    ]

    all_matches = []
    for pattern in patterns:
        all_matches.extend(re.findall(pattern, text_upper))

    # Remove duplicates and substrings
    unique_matches = sorted(set(all_matches), key=len, reverse=True)
    final_matches = []
    for match in unique_matches:
        if not any(match in longer for longer in final_matches):
            final_matches.append(match)

    return final_matches


def extract_karat_info(text):
    if not text:
        return None

    metals = extract_metals(text)
    if metals:
        value = metals[0].upper()

        # Normalize named metals
        for metal in ['PLATINUM', 'STERLING SILVER', 'SILVER', 'TITANIUM', 'BRASS', 'PALLADIUM', 'COPPER', 'ALLOY']:
            if metal in value:
                return metal.lower()

        # Normalize spacing and symbols
        if '&' in value:
            parts = [p.strip() for p in value.split('&')]
            value = ' & '.join(parts)

        # Fix concatenated names
        value = value.replace('WHITEGOLD', 'WHITE GOLD')
        value = value.replace('YELLOWGOLD', 'YELLOW GOLD')
        value = value.replace('ROSEGOLD', 'ROSE GOLD')
        value = value.replace('TWOTONE', 'TWO-TONE GOLD')
        value = value.replace('TWO TONE', 'TWO-TONE')

        # Convert CT/CARAT to K
        value = re.sub(r'(\d{1,2})(CT|CARAT)', r'\1K', value)
        value = re.sub(r'(\d{1,2}K)([A-Z])', r'\1 \2', value)

        return value.lower()

    # 🔍 Fallback: check for "Diamond <Metal>" structure
    diamond_metal_match = re.search(
        r'\bDIAMOND\s+(PLATINUM|STERLING\s+SILVER|SILVER|TITANIUM|BRASS|PALLADIUM|COPPER|ALLOY)\b',
        text.upper()
    )
    if diamond_metal_match:
        return diamond_metal_match.group(1).lower()

    # ✅ Final fallback: If "diamond" is in the text but no metal found
    if "DIAMOND" in text.upper():
        return "diamond"

    return None



def parse_ct(val):
    """Convert ct string to float, supporting composite fractions like 1-3/4"""
    try:
        if '-' in val and '/' in val:
            whole, frac = val.split('-')
            num, denom = frac.split('/')
            return int(whole) + float(num) / float(denom)
        if '/' in val:
            num, denom = val.split('/')
            return float(num) / float(denom)
        return float(val)
    except Exception:
        return None


def standardize_diawt_value(value):
    """Standardize diamond weight format (e.g., '0.5ct tw')"""
    if not value:
        return None

    value = str(value).strip().lower()

    # Normalize slashes and spacing
    value = re.sub(r'\s*/\s*', '/', value)
    value = re.sub(r'\s+', ' ', value)

    # Detect if 'tw' (or variants) exist
    has_tw = any(tw in value for tw in [' tw', 'tw', 't.w.', 'ctw'])

    # Extract the number portion (e.g., 0.5, 3/4, 1-1/2)
    num_match = re.search(r'(\d+-\d+/\d+|\d+/\d+|\d*\.\d+|\d+)', value)
    if not num_match:
        return None

    num_part = num_match.group(1)
    return f"{num_part}ct tw" if has_tw else f"{num_part}ct"

def extract_diamond_weight(text):
    """Extract smallest valid diamond weight (ct), preserving 'tw' and handling formats like 0,50 ct"""
    if not text:
        return None

    text = str(text).upper()

    # Convert European decimal (comma) to dot
    text = text.replace(',', '.')

    # Remove metal descriptors only if at start
    metal_free_text = re.sub(
        r'^\s*\d{1,2}(?:K|CT|CARAT)(?:\s*(?:[A-Z]+\s*&\s*[A-Z]+|ROSE|WHITE|YELLOW|STRAWBERRY|TWO-TONE)\s*GOLD)?\s*',
        '',
        text,
        flags=re.IGNORECASE
    )

    if any(x in metal_free_text for x in ['CUBIC ZIRCONIA', 'SAPPHIRE', 'CREATED']):
        return None

    # Match patterns: 1-3/4, 3/4, 0.25, 0,50, 1.25, etc. with ct indicators
    matches = re.findall(
        r'(\d+-\d+/\d+|\d+/\d+|\d*\.\d+|\d+)\s*(CTW|CT\s*TW|CT|CARAT\s*TW|CARAT|CT\.*\s*T*W*\.?)',
        metal_free_text,
        re.IGNORECASE
    )

    diamond_cts = []
    for val, unit in matches:
        ct_val = parse_ct(val)
        if ct_val is not None and ct_val < 5.0:
            diamond_cts.append((val.strip(), unit.strip(), ct_val))

    if not diamond_cts:
        return None

    # Pick the smallest valid ct
    smallest = min(diamond_cts, key=lambda x: x[2])
    return standardize_diawt_value(f"{smallest[0]} {smallest[1]}")

def extract_price(price_text):
    """Extract current price from price text"""
    if not price_text:
        return None
    
    # Look for the first price (current price)
    price_match = re.search(r'\$[\d,]+(?:\.\d{2})?', str(price_text))
    if price_match:
        return price_match.group(0)
    
    return None

def insert_into_db(data):
    """Insert scraped data into the MSSQL database"""
    if not data:
        log_event("No data to insert into the database.")
        return
    
    try:
        with pymssql.connect(**DB_CONFIG) as conn:
            with conn.cursor() as cursor:
                query = """
                    INSERT INTO dbo.IBM_Algo_Webstudy_Products 
                    (unique_id, CurrentDate, Header, ProductName, ImagePath, Kt, Price, TotalDiaWt, AdditionalInfo)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                """
                
                processed_data = [process_row(row) for row in data]
                # Filter out None values
                processed_data = [row for row in processed_data if row is not None]
                
                if processed_data:
                    cursor.executemany(query, processed_data)
                    conn.commit()
                    logger.info(f"Inserted {len(processed_data)} records successfully.")
                else:
                    logger.warning("No valid data to insert after processing.")
                
    except pymssql.DatabaseError as e:
        logger.error(f"Database error: {e}")
    except Exception as e:
        logger.error(f"Unexpected error: {e}")

class ScrapingService:
    @staticmethod
    def parse_product_data(product_data):
        """Parse product data from frontend JSON"""
        try:
            title = product_data.get('title', '')
            price_text = product_data.get('price', '')
            
            # Extract karat information
            kt = extract_karat_info(title)
            
            # Extract diamond weight
            diamond_weight = extract_diamond_weight(title)
            
            # Extract price information
            current_price = extract_price(price_text)
            
            # Extract original price and discount
            original_price = None
            discount = None
            
            if price_text:
                price_parts = str(price_text).split('\n')
                prices_found = []
                for part in price_parts:
                    part = part.strip()
                    price_match = re.search(r'\$[\d,]+(?:\.\d{2})?', part)
                    if price_match:
                        prices_found.append(price_match.group(0))
                    elif '% off' in part:
                        discount = part
            
                if len(prices_found) > 1:
                    original_price = prices_found[1]  # Second price is usually original
            
            additional_info = ""
            if original_price:
                additional_info += f"Original Price: {original_price}"
            if discount:
                additional_info += f", Discount: {discount}"
            
            return {
                'product_name': title,
                'kt': kt,
                'diamond_weight': diamond_weight,
                'price': current_price,
                'original_price': original_price,
                'discount': discount,
                'additional_info': additional_info.strip(', '),
                'image_url': product_data.get('image'),
                'link': product_data.get('link')
            }
        except Exception as e:
            logger.error(f"Error parsing product data: {e}")
            return {}

    @staticmethod
    def modify_image_url(image_url):
        """Modify the image URL to replace '_260' with '_1200' while keeping query parameters."""
        if not image_url or image_url == "N/A":
            return image_url

        try:
            # Handle case where image_url might be a list or other type
            image_url_str = str(image_url)
            
            query_params = ""
            if "?" in image_url_str:
                image_url_str, query_params = image_url_str.split("?", 1)
                query_params = f"?{query_params}"

            modified_url = re.sub(r'(_260)(?=\.\w+$)', '_1200', image_url_str)
            return modified_url + query_params
        except Exception as e:
            logger.error(f"Error modifying image URL {image_url}: {e}")
            return image_url

    @staticmethod
    def download_image(image_url, product_name, timestamp, image_folder, unique_id, retries=3):
        """Synchronous image download"""
        if not image_url or image_url == "N/A":
            return "N/A"

        # Clean filename
        # safe_product_name = re.sub(r'[^\w\-_.]', '_', product_name)[:100]
        # image_filename = f"{unique_id}_{safe_product_name}.jpg"
        # image_full_path = os.path.join(image_folder, image_filename)
        # modified_url = ScrapingService.modify_image_url(image_url)

        image_filename = f"{unique_id}_{timestamp}.jpg"
        image_full_path = os.path.join(image_folder, image_filename)
        modified_url = ScrapingService.modify_image_url(image_url)

        for attempt in range(retries):
            try:
                response = requests.get(modified_url, timeout=30)
                response.raise_for_status()
                
                # Verify it's actually an image
                content_type = response.headers.get('content-type', '')
                if not content_type.startswith('image/'):
                    logger.warning(f"URL {modified_url} returned non-image content type: {content_type}")
                    continue
                    
                with open(image_full_path, "wb") as f:
                    f.write(response.content)
                
                logger.info(f"Successfully downloaded image for {product_name}")
                return image_full_path
                
            except requests.RequestException as e:
                logger.warning(f"Retry {attempt + 1}/{retries} - Error downloading {product_name}: {e}")
                if attempt < retries - 1:
                    import time
                    time.sleep(2)  # Wait before retry
        
        logger.error(f"Failed to download {product_name} after {retries} attempts.")
        return "N/A"

@app.route('/api/scrape/save', methods=['POST'])
def save_scraped_data():
    """Save scraped product data to database and generate Excel file"""
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No data provided'}), 400

        products_data = data.get('products', [])
        page_title = data.get('page_title', 'Unknown Page')
        print("=================== Page Title ==================")
        print(page_title)
        print("=================== Page Title ==================")

        
        if not products_data:
            return jsonify({'error': 'No products data provided'}), 400

        current_date = datetime.now().date()
        current_time = datetime.now().time()
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        # Create folders for this scrape session
        session_id = str(uuid.uuid4())
        # Prepare directories and files
        os.makedirs(EXCEL_DATA_PATH, exist_ok=True)
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        image_folder = os.path.join(IMAGE_SAVE_PATH, timestamp)
        os.makedirs(image_folder, exist_ok=True)
        
        excel_filename = f"scraped_products_{timestamp}.xlsx"
        excel_path = os.path.join(EXCEL_DATA_PATH, excel_filename)

        # Create Excel workbook
        wb = Workbook()
        sheet = wb.active
        sheet.title = "Scraped Products"
        
        # Add headers
        headers = [
            'Unique ID', 'Current Date', 'Header', 'Product Name', 
            'Image Path', 'Kt', 'Price', 'Total Diamond Weight', 
            'Additional Info', 'Scrape Time', 'Image URL', 'Product Link'
        ]
        sheet.append(headers)

        database_records = []
        successful_downloads = 0

        for i, product_data in enumerate(products_data):
            try:
                parsed_data = ScrapingService.parse_product_data(product_data)
                
                unique_id = str(uuid.uuid4())
                product_name = parsed_data.get('product_name', 'Unknown Product')[:495]
                
                # Download image synchronously
                image_url = parsed_data.get('image_url')
                image_path = ScrapingService.download_image(
                    image_url, product_name, timestamp, image_folder, unique_id
                )
                
                if image_path != "N/A":
                    successful_downloads += 1

                # Prepare database record
                db_record = {
                    'unique_id': unique_id,
                    'current_date': current_date,
                    'page_title': page_title[:495],
                    'product_name': product_name,
                    'image_path': image_path,
                    'price': parsed_data.get('price'),
                    'diamond_weight': parsed_data.get('diamond_weight'),
                    'additional_info': parsed_data.get('additional_info', '')
                }
                
                database_records.append(db_record)

                # Add to Excel
                sheet.append([
                    unique_id,
                    current_date.strftime('%Y-%m-%d'),
                    page_title,
                    product_name,
                    image_path,
                    parsed_data.get('kt'),
                    parsed_data.get('price'),
                    parsed_data.get('diamond_weight'),
                    parsed_data.get('additional_info', ''),
                    current_time.strftime('%H:%M:%S'),
                    image_url,
                    product_data.get('link', '')
                ])

                logger.info(f"Processed product {i+1}/{len(products_data)}: {product_name}")

            except Exception as e:
                logger.error(f"Error processing product {i}: {e}")
                continue

        # Insert into database
        if database_records:
            insert_into_db(database_records)
            logger.info(f"Inserted {len(database_records)} records into database")

        # Save Excel file
        wb.save(excel_path)
        logger.info(f"Saved Excel file: {excel_path}")

        return jsonify({
            'message': f'Successfully processed {len(database_records)} products',
            'session_id': session_id,
            'excel_file': excel_filename,
            'total_processed': len(database_records),
            'images_downloaded': successful_downloads,
            'failed': len(products_data) - len(database_records)
        }), 200

    except Exception as e:
        logger.error(f"Error saving scraped data: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/products', methods=['GET'])
def get_products():
    """Get all scraped products from database"""
    try:
        with pymssql.connect(**DB_CONFIG) as conn:
            with conn.cursor(as_dict=True) as cursor:
                cursor.execute("""
                    SELECT TOP 100 
                        unique_id, CurrentDate, Header, ProductName, 
                        ImagePath, Kt, Price, TotalDiaWt, AdditionalInfo,
                        CreatedDate
                    FROM dbo.IBM_Algo_Webstudy_Products 
                    ORDER BY CreatedDate DESC
                """)
                products = cursor.fetchall()
                
                # Convert to list of dictionaries
                result = []
                for product in products:
                    result.append({
                        'unique_id': product['unique_id'],
                        'current_date': product['CurrentDate'].isoformat() if product['CurrentDate'] else None,
                        'header': product['Header'],
                        'product_name': product['ProductName'],
                        'image_path': product['ImagePath'],
                        'kt': product['Kt'],
                        'price': product['Price'],
                        'total_dia_wt': product['TotalDiaWt'],
                        'additional_info': product['AdditionalInfo'],
                        'created_date': product['CreatedDate'].isoformat() if product['CreatedDate'] else None
                    })
                
                return jsonify({
                    'products': result,
                    'total': len(result)
                }), 200
                
    except Exception as e:
        logger.error(f"Error fetching products: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/products/search', methods=['GET'])
def search_products():
    """Search products by various criteria"""
    try:
        query = request.args.get('q', '')
        kt = request.args.get('kt', '')
        
        sql_query = """
            SELECT TOP 50 
                unique_id, CurrentDate, Header, ProductName, 
                ImagePath, Kt, Price, TotalDiaWt, AdditionalInfo
            FROM dbo.IBM_Algo_Webstudy_Products 
            WHERE 1=1
        """
        params = []
        
        if query:
            sql_query += " AND (ProductName LIKE %s OR Header LIKE %s)"
            params.extend([f'%{query}%', f'%{query}%'])
            
        if kt:
            sql_query += " AND Kt LIKE %s"
            params.append(f'%{kt}%')
        
        # sql_query += " ORDER BY CreatedDate DESC"
        
        with pymssql.connect(**DB_CONFIG) as conn:
            with conn.cursor(as_dict=True) as cursor:
                cursor.execute(sql_query, params)
                products = cursor.fetchall()
                
                result = []
                for product in products:
                    result.append({
                        'unique_id': product['unique_id'],
                        'current_date': product['CurrentDate'].isoformat() if product['CurrentDate'] else None,
                        'header': product['Header'],
                        'product_name': product['ProductName'],
                        'image_path': product['ImagePath'],
                        'kt': product['Kt'],
                        'price': product['Price'],
                        'total_dia_wt': product['TotalDiaWt'],
                        'additional_info': product['AdditionalInfo']
                    })
                
                return jsonify(result), 200
                
    except Exception as e:
        logger.error(f"Error searching products: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/download/excel/<filename>', methods=['GET'])
def download_excel(filename):
    """Download generated Excel file"""
    try:
        file_path = os.path.join(EXCEL_DATA_PATH, filename)
        if not os.path.exists(file_path):
            return jsonify({'error': 'File not found'}), 404
            
        return send_file(file_path, as_attachment=True)
        
    except Exception as e:
        logger.error(f"Error downloading file {filename}: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    try:
        with pymssql.connect(**DB_CONFIG) as conn:
            with conn.cursor() as cursor:
                cursor.execute("SELECT 1")
        return jsonify({'status': 'healthy', 'database': 'connected'}), 200
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return jsonify({'status': 'unhealthy', 'database': 'disconnected', 'error': str(e)}), 500

@app.route('/api/test', methods=['GET'])
def test_endpoint():
    """Test endpoint to verify the server is running"""
    return jsonify({
        'message': 'Server is running!',
        'timestamp': datetime.now().isoformat(),
        'endpoints': {
            '/api/scrape/save': 'POST - Save scraped data',
            '/api/products': 'GET - Get all products',
            '/api/products/search': 'GET - Search products',
            '/api/health': 'GET - Health check'
        }
    })

if __name__ == '__main__':
    logger.info("Starting Smart Scraper Backend Server...")
    logger.info(f"Excel data path: {EXCEL_DATA_PATH}")
    logger.info(f"Image save path: {IMAGE_SAVE_PATH}")
    app.run(debug=True, host='0.0.0.0', port=5000)