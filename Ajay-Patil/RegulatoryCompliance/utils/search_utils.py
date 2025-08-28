# search_utils.py
import os
import re
import time
import requests
from typing import Optional, Tuple, List, Dict
from urllib.parse import urlparse

from langchain_community.document_loaders import WebBaseLoader, PyPDFLoader
from exception.custom_exception import CustomException
from logger.custom_logger import CustomLogger

# Initialize logger (module-level so utils can log too)
logger = CustomLogger().get_logger(__name__)

# ==== Configuration / Constants (utility things moved here) ====
DOWNLOAD_DIR = "downloaded_docs"
VECTORSTORE_DIR = "vectorstore"
REQUEST_TIMEOUT = 30
MAX_DOWNLOADS = 15
HEADERS = {
    'User-Agent': ('Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
                   'AppleWebKit/537.36 (KHTML, like Gecko) '
                   'Chrome/91.0.4472.124 Safari/537.36')
}

# Enhanced Domain whitelist with regulatory focus
TRUSTED_DOMAINS: Dict[str, List[str]] = {
    'india': [
        'cdsco.gov.in', 'ipc.gov.in', 'pharmaceuticals.gov.in',
        'who.int', 'ich.org', 'usp.org', 'edqm.eu', 'pharmacopoeia.com',
        'fda.gov', 'ema.europa.eu', 'pmda.go.jp', 'tga.gov.au',
        'pharmabiz.com', 'pharmatutor.org', 'sciencedirect.com',
        'researchgate.net', 'springer.com', 'pharmasm.com',
        'ncbi.nlm.nih.gov', 'pubmed.ncbi.nlm.nih.gov', 'frontiersin.org',
        'mdpi.com', 'acs.org', 'rsc.org'
    ],
    'default': [
        'fda.gov', 'ema.europa.eu', 'who.int', 'ich.org',
        'usp.org', 'edqm.eu', 'pmda.go.jp', 'tga.gov.au',
        'ncbi.nlm.nih.gov', 'sciencedirect.com', 'researchgate.net',
        'springer.com', 'mdpi.com', 'frontiersin.org',
        'pubmed.ncbi.nlm.nih.gov', 'acs.org', 'rsc.org'
    ]
}


def initialize_environment() -> None:
    """Create necessary directories."""
    try:
        os.makedirs(DOWNLOAD_DIR, exist_ok=True)
        os.makedirs(VECTORSTORE_DIR, exist_ok=True)
        logger.info(f"Initialized directories: {DOWNLOAD_DIR}, {VECTORSTORE_DIR}")
    except Exception as e:
        error_msg = f"Failed to initialize environment: {str(e)}"
        logger.error(error_msg)
        raise CustomException(error_msg, e)


def is_relevant_url(url: str, region: str) -> bool:
    """Check if URL is from a trusted domain with enhanced matching."""
    try:
        domain = urlparse(url).netloc.lower()
        domain = re.sub(r'^www\.', '', domain)
        trusted_domains = TRUSTED_DOMAINS.get(region.lower(), TRUSTED_DOMAINS['default'])
        result = any(domain.endswith(td) for td in trusted_domains)
        logger.debug(f"URL relevance check: {url} -> {result}")
        return result
    except Exception as e:
        logger.error(f"URL relevance check failed for {url}: {str(e)}")
        return False


def sanitize_filename(filename: str) -> str:
    """Sanitize filename to be filesystem-safe with improved handling."""
    try:
        filename = re.sub(r'[^\w\-_. ]', '_', filename)
        if len(filename) > 150:
            name, ext = os.path.splitext(filename)
            filename = name[:150 - len(ext)] + ext
        return filename
    except Exception as e:
        error_msg = f"Filename sanitization failed: {str(e)}"
        logger.error(error_msg)
        raise CustomException(error_msg, e)


def download_content(url: str) -> Tuple[Optional[str], Optional[str]]:
    """Download content from URL and save locally with enhanced handling."""
    try:
        from . import search_utils as _u  # safe if used in package; else ignore
    except Exception:
        _u = None  # not needed; keep compatibility whether package or flat files

    try:
        parsed = urlparse(url)
        if not all([parsed.scheme, parsed.netloc]):
            error_msg = f"Invalid URL: {url}"
            logger.error(error_msg)
            raise CustomException(error_msg)

        domain_part = parsed.netloc.replace('www.', '').split('.')[0]
        path_part = os.path.splitext(os.path.basename(parsed.path))[0][:50]
        timestamp = int(time.time())
        filename = f"{domain_part}_{path_part}_{timestamp}"
        filepath = os.path.join(DOWNLOAD_DIR, filename)

        existing_files = [f for f in os.listdir(DOWNLOAD_DIR) if f.startswith(f"{domain_part}_{path_part}")]
        if existing_files:
            logger.info(f"Using existing file for {url}: {existing_files[0]}")
            return os.path.join(DOWNLOAD_DIR, existing_files[0]), None

        logger.info(f"Downloading content from {url}")
        response = requests.get(url, headers=HEADERS, stream=True, timeout=REQUEST_TIMEOUT)
        response.raise_for_status()

        content_type = response.headers.get('Content-Type', '') or ''

        if 'application/pdf' in content_type:
            filepath += '.pdf'
        elif 'text/html' in content_type:
            filepath += '.html'
        elif 'text/plain' in content_type:
            filepath += '.txt'
        else:
            # Fallback based on URL
            if url.lower().endswith('.pdf'):
                filepath += '.pdf'
            elif url.lower().endswith(('.html', '.htm')):
                filepath += '.html'
            else:
                filepath += '.html'

        temp_filepath = filepath + '.download'
        with open(temp_filepath, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                if chunk:
                    f.write(chunk)

        if os.path.getsize(temp_filepath) > 1024:
            os.rename(temp_filepath, filepath)
            logger.info(f"Successfully downloaded {url} to {filepath}")
            return filepath, content_type
        else:
            os.remove(temp_filepath)
            logger.warning(f"Downloaded file too small: {url}")
            return None, None

    except requests.exceptions.RequestException as e:
        logger.error(f"Failed to download {url}: {str(e)}")
        return None, None
    except Exception as e:
        error_msg = f"Unexpected error downloading {url}: {str(e)}"
        logger.error(error_msg)
        raise CustomException(error_msg, e)


def load_document(filepath: str, content_type: str = None) -> Optional[List]:
    """Load document based on its type with enhanced error handling."""
    try:
        logger.info(f"Loading document: {filepath}")
        if filepath.lower().endswith('.pdf') or (content_type and 'pdf' in content_type.lower()):
            loader = PyPDFLoader(filepath)
            docs = loader.load()
            for doc in docs:
                doc.metadata['document_type'] = 'pdf'
            logger.info(f"Loaded {len(docs)} pages from PDF: {filepath}")
            return docs
        else:
            loader = WebBaseLoader(filepath)
            docs = loader.load()
            for doc in docs:
                doc.metadata['document_type'] = 'web'
            logger.info(f"Loaded web content from: {filepath}")
            return docs
    except Exception as e:
        logger.error(f"Failed to load {filepath}: {str(e)}")
        return None
