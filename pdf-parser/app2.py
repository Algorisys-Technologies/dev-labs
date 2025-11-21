"""
Optimized Table Extraction Service using Docling and EasyOCR
- Docling: fast pipeline configuration + PyMuPDF backend
- EasyOCR: single Reader instance + optional threaded OCR fallback
- Page-range processing + concurrency for faster runs on CPU
"""

import json
import csv
import io
import os
from pathlib import Path
from typing import List, Dict, Union, Literal, Optional
import logging
from concurrent.futures import ThreadPoolExecutor, as_completed

# OCR & PDF libraries
import easyocr

# Docling imports (ensure docling is installed)
from docling.document_converter import DocumentConverter, PdfFormatOption
from docling.datamodel.base_models import InputFormat
from docling.datamodel.pipeline_options import PdfPipelineOptions, TableFormerMode
# Fast backend
try:
    from docling.backend.pypdfium2_backend import PyPdfiumDocumentBackend
    BACKEND = PyPdfiumDocumentBackend
except Exception:
    # Fallback if backend module name differs in your docling version
    BACKEND = None

# Optional fast PDF metadata with PyMuPDF
try:
    import fitz  # PyMuPDF
except Exception:
    fitz = None

import pandas as pd

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


class TableExtractionService:
    def __init__(
        self,
        languages: Optional[List[str]] = None,
        use_gpu: bool = False,
        docling_table_mode: str = "fast",  # "fast" or "accurate"
        pages: Optional[List[int]] = None,
        ocr_workers: int = 4,
    ):
        """
        Args:
            languages: languages list for EasyOCR (default ['en'])
            use_gpu: whether EasyOCR should use GPU (if available)
            docling_table_mode: 'fast' (lighter TableFormer) or 'accurate' (slower)
            pages: list of 0-based page indices to process (None => all pages)
            ocr_workers: number of threads for OCR fallback
        """
        self.languages = languages or ["en"]
        self.use_gpu = use_gpu
        self.ocr_workers = max(1, int(ocr_workers))
        self.pages = pages

        # Initialize EasyOCR reader once and reuse
        logger.info(f"Initializing EasyOCR reader (gpu={self.use_gpu})...")
        print("pages =>", self.pages, "\n")
        self.reader = easyocr.Reader(self.languages, gpu=self.use_gpu, verbose=False)

        # Configure Docling's pipeline options (fast defaults)
        pipeline_options = PdfPipelineOptions()

        # ** DEFAULT OPTIMIZATIONS **
        # Disable heavy features you may not need
        pipeline_options.do_ocr = False  # We'll use EasyOCR separately if needed

        # TableFormer mode selection
        if docling_table_mode == "accurate":
            pipeline_options.do_table_structure = True
            pipeline_options.table_structure_options.mode = TableFormerMode.ACCURATE
        else:
            # FAST mode uses a lighter model / heuristics
            pipeline_options.do_table_structure = True
            pipeline_options.table_structure_options.mode = TableFormerMode.FAST

        # Choose backend: PyMuPDF if available (faster) else default
        if BACKEND is not None:
            try:
                logger.info("Using PyMuPDF backend for Docling (fast).")
                self.converter = DocumentConverter(
                    allowed_formats=[InputFormat.PDF, InputFormat.IMAGE],
                    format_options={
                        InputFormat.PDF: PdfFormatOption(
                            pipeline_options=pipeline_options,
                            backend=BACKEND,
                            pages=self.pages
                        )
                    },
                )
            except Exception as e:
                logger.warning(f"PyMuPDF backend init failed: {e}. Falling back to default backend.")
                self.converter = DocumentConverter(
                    allowed_formats=[InputFormat.PDF, InputFormat.IMAGE],
                    format_options={
                        InputFormat.PDF: PdfFormatOption(pipeline_options=pipeline_options, pages=self.pages)
                    },
                )
        else:
            logger.info("PyMuPDF backend not available in docling. Using default backend.")
            self.converter = DocumentConverter(
                allowed_formats=[InputFormat.PDF, InputFormat.IMAGE],
                format_options={
                    InputFormat.PDF: PdfFormatOption(pipeline_options=pipeline_options, pages=self.pages)
                },
                pages=self.pages
            )

    # ----------------------------
    # Basic helpers
    # ----------------------------
    @staticmethod
    def _ensure_file_exists(path: str) -> bool:
        if not os.path.exists(path):
            logger.error(f"File not found: {path}")
            return False
        return True

    # ----------------------------
    # EasyOCR extraction (reused reader)
    # ----------------------------
    def extract_with_easyocr(self, image_path: str) -> List[Dict]:
        """
        Run EasyOCR on an image and return list of detections:
            [{'bbox': [...], 'text': '...', 'confidence': 0.9}, ...]
        """
        if not self._ensure_file_exists(image_path):
            return []

        try:
            results = self.reader.readtext(image_path, detail=1)
            formatted = []
            for bbox, text, confidence in results:
                formatted.append({"bbox": bbox, "text": text, "confidence": float(confidence)})
            return formatted
        except Exception as e:
            logger.error(f"EasyOCR error for {image_path}: {e}", exc_info=True)
            return []

    # ----------------------------
    # Docling extraction
    # ----------------------------
    def extract_with_docling(self, file_path: str):
        """Runs DocumentConverter.convert() (Docling)"""
        if not self._ensure_file_exists(file_path):
            return None
        try:
            res = self.converter.convert(file_path)
            return res
        except Exception as e:
            logger.error(f"Docling convert error for {file_path}: {e}", exc_info=True)
            return None

    # ----------------------------
    # Table parsing helpers
    # ----------------------------
    def parse_table_to_rows(self, table_element) -> List[List[str]]:
        """Convert docling table element to list-of-rows"""
        rows = []
        try:
            if hasattr(table_element, "data") and hasattr(table_element.data, "table_cells"):
                table_cells = table_element.data.table_cells
                grouped_rows = {}
                for cell in table_cells:
                    row_idx = cell.start_row_offset_idx
                    col_idx = cell.start_col_offset_idx
                    grouped_rows.setdefault(row_idx, {})[col_idx] = (cell.text or "").strip()
                for r in sorted(grouped_rows.keys()):
                    row = [grouped_rows[r].get(c, "") for c in sorted(grouped_rows[r].keys())]
                    rows.append(row)
        except Exception as e:
            logger.debug(f"Error parsing docling table: {e}", exc_info=True)
        return rows

    @staticmethod
    def _to_csv_string(rows: List[List[str]]) -> str:
        output = io.StringIO()
        writer = csv.writer(output)
        writer.writerows(rows)
        return output.getvalue()

    @staticmethod
    def _rows_to_json(rows: List[List[str]]) -> List[Dict]:
        if not rows:
            return []
        headers = rows[0]
        data = []
        for row in rows[1:]:
            row_dict = {headers[i] if i < len(headers) else f"col_{i}": (row[i] if i < len(row) else "") for i in range(len(headers))}
            data.append(row_dict)
        return data

    # ----------------------------
    # OCR fallback grouping + concurrency
    # ----------------------------
    def _group_ocr_into_table(self, ocr_results: List[Dict], y_threshold: int = 20) -> List[List[str]]:
        if not ocr_results:
            return []
        # sort by top-left y
        sorted_results = sorted(ocr_results, key=lambda x: x["bbox"][0][1])
        rows = []
        current_row = []
        last_y = None
        for item in sorted_results:
            y_coord = item["bbox"][0][1]
            if last_y is None or abs(y_coord - last_y) < y_threshold:
                current_row.append(item)
            else:
                if current_row:
                    current_row.sort(key=lambda x: x["bbox"][0][0])
                    rows.append([itm["text"] for itm in current_row])
                current_row = [item]
            last_y = y_coord
        if current_row:
            current_row.sort(key=lambda x: x["bbox"][0][0])
            rows.append([itm["text"] for itm in current_row])
        return rows

    def _ocr_fallback_parallel(self, images: List[str]) -> List[List[List[str]]]:
        """
        Run EasyOCR on multiple images in parallel using threads.
        Returns list of rows per image: [rows_img1, rows_img2, ...]
        """
        results = []
        with ThreadPoolExecutor(max_workers=self.ocr_workers) as ex:
            future_to_image = {ex.submit(self.extract_with_easyocr, img): img for img in images}
            for fut in as_completed(future_to_image):
                img = future_to_image[fut]
                try:
                    ocr = fut.result()
                    rows = self._group_ocr_into_table(ocr)
                    results.append(rows)
                except Exception as e:
                    logger.error(f"OCR failed for {img}: {e}", exc_info=True)
        return results

    # ----------------------------
    # Main extract_tables method
    # ----------------------------
    def extract_tables(
        self,
        file_path: str,
        output_format: Literal["csv", "json", "both"] = "both",
        output_dir: Optional[str] = None,
        ocr_image_pages: bool = True  # whether to run OCR fallback on pages as images
    ) -> Dict[str, Union[str, List[Dict]]]:
        """
        Extract tables from PDF/image with Docling first; if no tables found, fallback to EasyOCR.
        """
        results = {"file": file_path, "tables": []}
        if not self._ensure_file_exists(file_path):
            results["error"] = "file_not_found"
            return results

        docling_result = self.extract_with_docling(file_path)
        doc_filename = Path(file_path).stem

        # Save docling json if any
        if docling_result is not None:
            try:
                dict_data = docling_result.document.export_to_dict(mode="json")
                filtered = {k: dict_data.get(k) for k in ["schema_name", "version", "name", "origin", "tables"] if k in dict_data}
                if output_format in ("json", "both") and output_dir:
                    json_path = Path(output_dir) / f"{doc_filename}_docling.json"
                    json_path.parent.mkdir(parents=True, exist_ok=True)
                    json_path.write_text(json.dumps(filtered, indent=2))
                    logger.info(f"Saved Docling JSON: {json_path}")
            except Exception as e:
                logger.debug(f"Could not export docling json: {e}")

            # parse tables from docling result
            try:
                tables = getattr(docling_result.document, "tables", []) or []
                for idx, table in enumerate(tables):
                    rows = self.parse_table_to_rows(table)
                    table_info = {
                        "table_index": idx,
                        "rows": rows,
                        "row_count": len(rows),
                        "column_count": len(rows[0]) if rows else 0,
                        "method": "docling"
                    }
                    # store csv/json if requested
                    if output_format in ("csv", "both") and output_dir:
                        df: pd.DataFrame = table.export_to_dataframe(doc=docling_result.document)
                        csv_path = Path(output_dir) / f"{doc_filename}_docling_table_{idx+1}.csv"
                        df.to_csv(csv_path, index=False)
                        logger.info(f"Saved Docling CSV: {csv_path}")
                    results["tables"].append(table_info)
            except Exception as e:
                logger.error(f"Error parsing docling tables: {e}", exc_info=True)

        # If docling found no tables, do OCR fallback
        if not results["tables"]:
            logger.info("No tables found via Docling — running EasyOCR fallback.")
            images_for_ocr = []

            # If file is PDF and fitz is available, render pages to images of selected pages
            if fitz is not None and file_path.lower().endswith(".pdf") and ocr_image_pages:
                doc = fitz.open(file_path)
                page_indices = self.pages if self.pages is not None else list(range(len(doc)))
                for p in page_indices:
                    try:
                        page = doc.load_page(p)
                        pix = page.get_pixmap(dpi=200)  # moderate DPI for faster OCR
                        img_bytes = pix.tobytes("png")
                        tmp_image = Path(output_dir or ".") / f"{doc_filename}_page_{p+1}.png"
                        tmp_image.write_bytes(img_bytes)
                        images_for_ocr.append(str(tmp_image))
                    except Exception as e:
                        logger.debug(f"Failed to render page {p} -> {e}")

            # If input is an image, just OCR it
            if file_path.lower().endswith((".png", ".jpg", ".jpeg", ".tiff", ".bmp")):
                images_for_ocr.append(file_path)

            # Run OCR in parallel if multiple pages
            ocr_pages_rows = []
            if images_for_ocr:
                ocr_pages_rows = self._ocr_fallback_parallel(images_for_ocr)

            # Convert found rows to results
            for idx, rows in enumerate(ocr_pages_rows):
                if not rows:
                    continue
                table_data = {
                    "table_index": idx,
                    "rows": rows,
                    "row_count": len(rows),
                    "column_count": len(rows[0]) if rows else 0,
                    "method": "easyocr"
                }
                if output_format in ("csv", "both"):
                    csv_string = self._to_csv_string(rows)
                    table_data["csv"] = csv_string
                    if output_dir:
                        csv_path = Path(output_dir) / f"{doc_filename}_easyocr_table_{idx+1}.csv"
                        csv_path.parent.mkdir(parents=True, exist_ok=True)
                        csv_path.write_text(csv_string)
                        logger.info(f"Saved EasyOCR CSV: {csv_path}")
                if output_format in ("json", "both"):
                    json_rows = self._rows_to_json(rows)
                    table_data["json"] = json_rows
                    if output_dir:
                        json_path = Path(output_dir) / f"{doc_filename}_easyocr_table_{idx+1}.json"
                        json_path.parent.mkdir(parents=True, exist_ok=True)
                        json_path.write_text(json.dumps(json_rows, indent=2))
                        logger.info(f"Saved EasyOCR JSON: {json_path}")

                results["tables"].append(table_data)

        return results


# ----------------------------
# Command line usage
# ----------------------------
def main():
    import argparse

    parser = argparse.ArgumentParser(description="Fast Table Extraction Service")
    parser.add_argument("file", help="PDF or image file to parse")
    parser.add_argument("--out", help="Output directory", default="output_tables")
    parser.add_argument("--pages", help="Pages to process (comma separated, 1-based)", default=None)
    parser.add_argument("--gpu", action="store_true", help="Use GPU for EasyOCR (if available)")
    parser.add_argument("--workers", type=int, default=4, help="Threads for OCR fallback")
    parser.add_argument("--mode", choices=["fast", "accurate"], default="fast", help="Docling table mode")
    args = parser.parse_args()

    # Parse pages argument
    pages = None
    if args.pages:
        try:
            pages = [int(x) - 1 for x in args.pages.split(",")]  # convert to 0-based
        except Exception:
            logger.warning("Invalid pages argument. Ignoring.")

    # Ensure output dir exists
    Path(args.out).mkdir(parents=True, exist_ok=True)

    service = TableExtractionService(
        languages=["en"],
        use_gpu=args.gpu,
        docling_table_mode=args.mode,
        pages=pages,
        ocr_workers=args.workers,
    )

    res = service.extract_tables(file_path=args.file, output_format="both", output_dir=args.out)
    print(json.dumps({"file": args.file, "tables_found": len(res.get("tables", []))}, indent=2))


if __name__ == "__main__":
    main()
