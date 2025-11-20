"""
Table Extraction Service using Docling and EasyOCR
Extracts tabular data from PDFs (text or image-based) and images, converts to CSV/JSON
"""

import json
import csv
import io
import os
from pathlib import Path
from typing import List, Dict, Union, Literal
import easyocr
from docling.document_converter import DocumentConverter, PdfFormatOption
from docling.datamodel.base_models import InputFormat
from docling.datamodel.pipeline_options import PdfPipelineOptions, TableFormerMode
from docling.backend.pypdfium2_backend import PyPdfiumDocumentBackend
import fitz  # PyMuPDF
from PIL import Image
import numpy as np
import logging
import pandas as pd


# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class TableExtractionService:
    """Service for extracting tables from images using Docling and EasyOCR"""
    
    def __init__(self, languages: List[str] = None):
        """
        Initialize the service
        
        Args:
            languages: List of language codes for OCR (default: ['en'])
        """
        self.languages = languages or ['en']
        self.reader = easyocr.Reader(self.languages, gpu=False)
        
        # Configure Docling with table extraction enabled
        pipeline_options = PdfPipelineOptions()
        pipeline_options.do_table_structure = True
        pipeline_options.table_structure_options.mode = TableFormerMode.ACCURATE
        
        self.converter = DocumentConverter(
            allowed_formats=[
                InputFormat.IMAGE,
                InputFormat.PDF,
            ],
            format_options={
                InputFormat.PDF: PdfFormatOption(pipeline_options=pipeline_options)
            }
        )
    
    import os

    def extract_with_easyocr(self, image_path: str):
        """
        Extract text from image using EasyOCR
        
        Args:
            image_path: Path to the image file
            
        Returns:
            List of detected text with bounding boxes
        """
        # Check if the file exists
        if not os.path.exists(image_path):
            logger.error(f"File not found: {image_path}")
            return []
            
        
        # Check if the file is a valid image format
        valid_extensions = ['.jpg', '.jpeg', '.png', '.bmp', '.tiff']
        if not any(image_path.lower().endswith(ext) for ext in valid_extensions):
            logger.error(f"Unsupported file format: {image_path}")
            return []
        
        try:
            # Process the image with EasyOCR
            results = self.reader.readtext(image_path)
            
            # Format results
            formatted_results = []
            for bbox, text, confidence in results:
                formatted_results.append({
                    'bbox': bbox,
                    'text': text,
                    'confidence': confidence
                })
            
            return formatted_results
        
        except Exception as e:
            logger.error(f"Error processing image with EasyOCR: {e}", exc_info=True)
            return []
    
    def extract_with_docling(self, file_path: str) -> Dict:
        """
        Extract document structure including tables using Docling
        
        Args:
            file_path: Path to the image or PDF file
            
        Returns:
            Extracted document data with tables
        """
        result = self.converter.convert(file_path)
        return result
        
    
    def parse_table_to_rows(self, table_data) -> List[List[str]]:
        """
        Parse table data into rows and columns
        
        Args:
            table_data: Table element from Docling
            
        Returns:
            List of rows, each row is a list of cell values
        """
        rows = []
        
        # Check if table_data has the expected structure
        if hasattr(table_data, 'data') and hasattr(table_data.data, 'table_cells'):
            table_cells = table_data.data.table_cells
            
            # Group cells by row index
            grouped_rows = {}
            for cell in table_cells:
                row_idx = cell.start_row_offset_idx
                col_idx = cell.start_col_offset_idx
                
                if row_idx not in grouped_rows:
                    grouped_rows[row_idx] = {}
                
                grouped_rows[row_idx][col_idx] = cell.text
            
            # Sort rows and columns to create a 2D list
            for row_idx in sorted(grouped_rows.keys()):
                row = []
                for col_idx in sorted(grouped_rows[row_idx].keys()):
                    row.append(grouped_rows[row_idx][col_idx])
                rows.append(row)
        
        # Log the parsed rows for debugging
        logger.debug(f"Parsed rows: {rows}")
        
        return rows
    
    def extract_tables(
        self, 
        file_path: str,
        output_format: Literal['csv', 'json', 'both'] = 'both',
        output_dir: str = None
    ) -> Dict[str, Union[str, List[Dict]]]:
        """
        Main method to extract tables from image and convert to CSV/JSON
        
        Args:
            file_path: Path to the image file
            output_format: 'csv', 'json', or 'both'
            output_dir: Directory to save output files (optional)
            
        Returns:
            Dictionary with extracted data in requested formats
        """
        results = {
            'file': file_path,
            'tables': []
        }
        
        # First try Docling for structured extraction
        try:
            docling_result = self.extract_with_docling(file_path)

            doc_filename = docling_result.input.file.stem

            if output_format in ['json', 'both']:
                dict_data = docling_result.document.export_to_dict(mode="json")
                
                # Filter the dict_data to include only the required keys
                filtered_data = {
                    key: dict_data[key] for key in ['schema_name', 'version', 'name', 'origin', 'tables'] if key in dict_data
                }

                # Convert the filtered data to JSON
                json_output = json.dumps(filtered_data, indent=2)

                if output_dir:
                    json_path = Path(output_dir) / f"{doc_filename}_docling.json"
                    json_path.parent.mkdir(parents=True, exist_ok=True)
                    json_path.write_text(json_output)
                    logger.info(f"Saved Docling output as JSON to {json_path}")

            if output_format in ['csv', 'both']:
                for idx, table in enumerate(docling_result.document.tables):
                    table_df: pd.DataFrame = table.export_to_dataframe()

                    if output_dir:
                        csv_path = Path(output_dir) / f"{doc_filename}_docling_table_{idx + 1}.csv"
                        csv_path.parent.mkdir(parents=True, exist_ok=True)
                        table_df.to_csv(csv_path, index=False)
                        logger.info(f"Saved table {idx} as CSV to {csv_path}")

            if docling_result.document.tables:
                for idx, table in enumerate(docling_result.document.tables):
                    rows = self.parse_table_to_rows(table)

                    table_data = {
                        'table_index': idx,
                        'rows': rows,
                        'row_count': len(rows),
                        'column_count': len(rows[0]) if rows else 0,
                        'method': 'docling'
                    }

                    results['tables'].append(table_data)

            # If no tables found with Docling, fallback to EasyOCR
            if not results['tables']:
                logger.info("No tables found with Docling, trying EasyOCR...")
                ocr_results = self.extract_with_easyocr(file_path)
                
                # Group OCR results into potential table structure
                rows = self._group_ocr_into_table(ocr_results)
                
                if rows:
                    table_data = {
                        'table_index': 0,
                        'rows': rows,
                        'row_count': len(rows),
                        'column_count': len(rows[0]) if rows else 0,
                        'method': 'easyocr'
                    }
                    
                    if output_format in ['csv', 'both']:
                        csv_string = self._to_csv(rows)
                        table_data['csv'] = csv_string
                        
                        if output_dir:
                            csv_path = Path(output_dir) / "table_0.csv"
                            csv_path.parent.mkdir(parents=True, exist_ok=True)
                            csv_path.write_text(csv_string)
                            logger.info(f"Saved table 0 as CSV to {csv_path}")
                    
                    if output_format in ['json', 'both']:
                        json_data = self._to_json(rows)
                        table_data['json'] = json_data
                        
                        if output_dir:
                            json_path = Path(output_dir) / "table_0.json"
                            json_path.parent.mkdir(parents=True, exist_ok=True)
                            json_path.write_text(json.dumps(json_data, indent=2))
                            logger.info(f"Saved table 0 as JSON to {json_path}")
                    
                    results['tables'].append(table_data)
        
        except Exception as e:
            logger.error(f"Error during extraction: {e}", exc_info=True)
            results['error'] = str(e)
        
        return results
    
    def _group_ocr_into_table(self, ocr_results: List[Dict]) -> List[List[str]]:
        """
        Group OCR results into table structure based on spatial positioning
        
        Args:
            ocr_results: List of OCR detections with bounding boxes
            
        Returns:
            List of rows
        """
        if not ocr_results:
            return []
        
        # Sort by Y coordinate (top to bottom)
        sorted_results = sorted(ocr_results, key=lambda x: x['bbox'][0][1])
        
        # Group into rows based on Y coordinate proximity
        rows = []
        current_row = []
        last_y = None
        y_threshold = 20  # pixels
        
        for item in sorted_results:
            y_coord = item['bbox'][0][1]
            
            if last_y is None or abs(y_coord - last_y) < y_threshold:
                current_row.append(item)
            else:
                if current_row:
                    # Sort row by X coordinate (left to right)
                    current_row.sort(key=lambda x: x['bbox'][0][0])
                    rows.append([item['text'] for item in current_row])
                current_row = [item]
            
            last_y = y_coord
        
        # Add last row
        if current_row:
            current_row.sort(key=lambda x: x['bbox'][0][0])
            rows.append([item['text'] for item in current_row])
        
        return rows
    
    def _to_csv(self, rows: List[List[str]]) -> str:
        """Convert rows to CSV string"""
        output = io.StringIO()
        writer = csv.writer(output)
        writer.writerows(rows)
        return output.getvalue()
    
    def _to_json(self, rows: List[List[str]]) -> List[Dict]:
        """Convert rows to JSON (list of dictionaries with headers)"""
        if not rows:
            return []
        
        # Use first row as headers
        headers = rows[0]
        data = []
        
        for row in rows[1:]:
            row_dict = {}
            for i, header in enumerate(headers):
                value = row[i] if i < len(row) else ''
                row_dict[header] = value
            data.append(row_dict)
        
        return data


# Example usage
if __name__ == "__main__":
    # Initialize service
    service = TableExtractionService(languages=['en'])
    
    # Extract tables from image/pdf
    file_path = "Britannia Unaudited Q2 June 2026.pdf"  # Replace with your image/pdf path
    
    # Extract and save as both CSV and JSON
    results = service.extract_tables(
        file_path=file_path,
        output_format='both',
        output_dir='output_tables'
    )
    
    # Print results
    print(f"\nFound {len(results['tables'])} table(s)")
    
    for table in results['tables']:
        print(f"\nTable {table['table_index']}:")
        print(f"  Rows: {table['row_count']}")
        print(f"  Columns: {table['column_count']}")
        
        if 'csv' in table:
            print("\nCSV Preview:")
            print(table['csv'][:500])  # First 500 chars
        
        if 'json' in table:
            print("\nJSON Preview:")
            print(json.dumps(table['json'][:2], indent=2))  # First 2 rows