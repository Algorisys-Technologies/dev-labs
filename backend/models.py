from typing import Optional
from sqlmodel import SQLModel, Field

class Order(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    po_number: Optional[str] = None
    order_date: Optional[str] = None
    goods_name: Optional[str] = None
    quantity: Optional[int] = None
    location: Optional[str] = None
    category: str
    confidence: Optional[float] = None
    processed_at: Optional[str] = None
    status: str = Field(default="Added to Purchase Order")
    priority: Optional[str] = "Normal"
    supplier: Optional[str] = "N/A"
    amount: Optional[str] = "N/A"
    payment_terms: Optional[str] = "N/A"
    email_subject: Optional[str] = None
    email_body: Optional[str] = None
    raw_json: Optional[str] = None

class EmailInput(SQLModel):
    subject: str
    body: str
