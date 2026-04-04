from sqlmodel import Session, select, create_engine
import os
from .models import Order
from .database import engine

def view_orders():
    print("\n" + "="*80)
    print("📋 CURRENT POC DATABASE CONTENT")
    print("="*80)
    
    with Session(engine) as session:
        statement = select(Order)
        results = session.exec(statement).all()
        
        if not results:
            print("  ℹ️  The database is currently EMPTY.")
            print("     (Extracted orders will appear here only AFTER clicking 'Push to B1')")
        else:
            print(f"  ✅ Found {len(results)} Persistent Records:\n")
            # Table Header
            header = f"{'ID':<4} | {'PO #':<15} | {'Category':<15} | {'Status':<18}"
            print(header)
            print("-" * len(header))
            
            for order in results:
                print(f"{order.id:<4} | {str(order.po_number):<15} | {order.category:<15} | {order.status:<18}")
                
    print("="*80 + "\n")

if __name__ == "__main__":
    view_orders()
