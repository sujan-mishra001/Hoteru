"""
Report generation service
"""
from typing import Dict, List
from sqlalchemy.orm import Session
from datetime import datetime
from app.models.orders import Order
from app.utils.pdf_generator import generate_pdf_report, generate_invoice_pdf
from app.utils.excel_generator import generate_excel_report


class ReportService:
    """Service for report generation"""
    
    @staticmethod
    def get_sales_summary(db: Session) -> Dict:
        """Get sales summary report"""
        orders = db.query(Order).filter(Order.status == 'Completed').all()
        total_sales = sum(order.total_amount or 0 for order in orders)
        total_orders = len(orders)
        
        return {
            "total_sales": total_sales,
            "total_orders": total_orders,
            "average_order_value": total_sales / total_orders if total_orders > 0 else 0
        }
    
    @staticmethod
    def get_day_book(db: Session, date: datetime = None) -> List[Order]:
        """Get day book report for a specific date"""
        if date is None:
            date = datetime.now().date()
        
        orders = db.query(Order).filter(
            Order.created_at >= date
        ).all()
        
        return orders
    
    @staticmethod
    def generate_pdf_report(report_type: str, data: List[Dict], title: str = None) -> bytes:
        """Generate PDF report"""
        if title is None:
            title = report_type.replace('-', ' ').title()
        
        return generate_pdf_report(data, title)
    
    @staticmethod
    def generate_excel_report(report_type: str, data: List[Dict], title: str = None) -> bytes:
        """Generate Excel report"""
        if title is None:
            title = report_type.replace('-', ' ').title()
        
        return generate_excel_report(data, title)
    
    @staticmethod
    def generate_order_invoice(order_data: Dict) -> bytes:
        """Generate invoice PDF for an order"""
        return generate_invoice_pdf(order_data)
