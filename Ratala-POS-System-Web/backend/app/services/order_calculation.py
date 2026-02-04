"""
Order calculation service - centralized business logic for order amounts
"""
from sqlalchemy.orm import Session
from app.models.settings import CompanySettings


class OrderCalculationService:
    """Service to handle all order amount calculations uniformly"""
    
    @staticmethod
    def calculate_order_amounts(
        db: Session,
        items_subtotal: float,
        discount_amount: float = 0.0,
        branch_id: int = None
    ) -> dict:
        """
        Calculate all order amounts based on company settings
        
        Args:
            db: Database session
            items_subtotal: Sum of all item prices * quantities
            discount_amount: Discount amount (if any)
            branch_id: Branch ID for branch-specific settings (future use)
            
        Returns:
            dict with gross_amount, service_charge, tax, discount, net_amount
        """
        # Get company settings
        settings = db.query(CompanySettings).first()
        
        # Default rates if no settings found
        service_charge_rate = settings.service_charge_rate if settings else 10.0
        tax_rate = settings.tax_rate if settings else 13.0
        
        # Calculate amounts
        gross_amount = items_subtotal
        discount = discount_amount
        
        # Amount after discount
        amount_after_discount = gross_amount - discount
        
        # Service charge on amount after discount
        service_charge = round(amount_after_discount * (service_charge_rate / 100), 2)
        
        # Tax on (amount after discount + service charge)
        taxable_amount = amount_after_discount + service_charge
        tax = round(taxable_amount * (tax_rate / 100), 2)
        
        # Final net amount
        net_amount = round(amount_after_discount + service_charge + tax, 2)
        
        return {
            'gross_amount': round(gross_amount, 2),
            'discount': round(discount, 2),
            'service_charge': round(service_charge, 2),
            'service_charge_rate': service_charge_rate,
            'tax': round(tax, 2),
            'tax_rate': tax_rate,
            'net_amount': net_amount,
            'total_amount': net_amount  # For backward compatibility
        }
    
    @staticmethod
    def recalculate_order(db: Session, order_items: list, discount_amount: float = 0.0, branch_id: int = None) -> dict:
        """
        Recalculate order from items
        
        Args:
            db: Database session
            order_items: List of order items with price and quantity
            discount_amount: Discount amount
            branch_id: Branch ID
            
        Returns:
            Calculated amounts dictionary
        """
        items_subtotal = sum(
            item.get('price', 0) * item.get('quantity', 0) 
            for item in order_items
        )
        
        return OrderCalculationService.calculate_order_amounts(
            db, 
            items_subtotal, 
            discount_amount,
            branch_id
        )
