import socket
from typing import List, Optional, Dict, Any
from app.models.printer import Printer, PrinterBrand, PrinterConnection
import logging

logger = logging.getLogger(__name__)

# ESC/POS Constants
ESC = b'\x1b'
GS = b'\x1d'
LF = b'\n'

class ESCPOSGenerator:
    """Basic ESC/POS command generator for thermal printers."""
    
    @staticmethod
    def initialize():
        return ESC + b'@'

    @staticmethod
    def text(content: str):
        return content.encode('ascii', errors='replace') + LF

    @staticmethod
    def bold(enabled: bool = True):
        return ESC + b'E' + (b'\x01' if enabled else b'\x00')

    @staticmethod
    def align(position: str = 'left'):
        pos = {'left': b'\x00', 'center': b'\x01', 'right': b'\x02'}
        return ESC + b'a' + pos.get(position.lower(), b'\x00')

    @staticmethod
    def font_size(width: int = 1, height: int = 1):
        # width/height 1-8
        size = ((width - 1) << 4) | (height - 1)
        return GS + b'!' + bytes([size])

    @staticmethod
    def cut():
        return GS + b'V' + b'\x00'

    @staticmethod
    def line_feed(n: int = 1):
        return LF * n

class PrintingService:
    def __init__(self, db_session):
        self.db = db_session

    async def print_kot(self, kot: Any):
        """Print a Kitchen Order Ticket."""
        # KOT.order relationship is needed
        branch_id = kot.order.branch_id if kot.order else None
        if not branch_id:
            logger.error("KOT has no associated order or branch_id")
            return False

        printers = self.db.query(Printer).filter(
            Printer.is_active == True,
            Printer.branch_id == branch_id
        ).all()

        if not printers:
            logger.warning(f"No active KITCHEN printers found for branch: {branch_id}")
            return False

        success = True
        for printer in printers:
            try:
                content = self._format_kot(kot, printer)
                await self._send_to_printer(printer, content)
            except Exception as e:
                logger.error(f"Failed to print KOT to {printer.name}: {str(e)}")
                success = False
        
        return success

    async def print_bot(self, kot: Any):
        """Print a Bar Order Ticket."""
        branch_id = kot.order.branch_id if kot.order else None
        if not branch_id:
            logger.error("BOT has no associated order or branch_id")
            return False

        printers = self.db.query(Printer).filter(
            Printer.is_active == True,
            Printer.branch_id == branch_id
        ).all()

        if not printers:
            logger.warning(f"No active BAR printers found for branch: {branch_id}")
            return False

        success = True
        for printer in printers:
            try:
                content = self._format_kot(kot, printer, title="BAR ORDER")
                await self._send_to_printer(printer, content)
            except Exception as e:
                logger.error(f"Failed to print BOT to {printer.name}: {str(e)}")
                success = False
        
        return success

    async def print_bill(self, order: Any):
        """Print a Billing Receipt."""
        branch_id = order.branch_id
        printers = self.db.query(Printer).filter(
            Printer.is_active == True,
            Printer.branch_id == branch_id
        ).all()

        if not printers:
            logger.warning(f"No active BILLING printers found for branch: {branch_id}")
            return False

        success = True
        for printer in printers:
            try:
                content = self._format_billing_receipt(order, printer)
                await self._send_to_printer(printer, content)
            except Exception as e:
                logger.error(f"Failed to print Bill to {printer.name}: {str(e)}")
                success = False
        
        return success

    def _format_kot(self, kot: Any, printer: Printer, title: str = "KITCHEN ORDER") -> bytes:
        gen = ESCPOSGenerator
        data = gen.initialize()
        data += gen.align('center')
        data += gen.font_size(2, 2)
        data += gen.text(title)
        data += gen.line_feed(1)
        data += gen.font_size(1, 1)
        
        data += gen.align('left')
        data += gen.text(f"Ticket: {kot.kot_number}")
        data += gen.text(f"Table: {kot.order.table.table_id if (kot.order and kot.order.table) else 'N/A'}")
        data += gen.text(f"Waiter: {kot.user.full_name if kot.user else 'N/A'}")
        data += gen.text(f"Date: {kot.created_at.strftime('%Y-%m-%d %H:%M')}")
        data += gen.text("-" * (printer.paper_size // 2))
        
        data += gen.bold(True)
        col_width = 30 if printer.paper_size == 80 else 20
        data += gen.text(f"{'Item':<{col_width}} {'Qty':>5}")
        data += gen.bold(False)
        
        for item in kot.items:
            item_name = item.menu_item.name if item.menu_item else "Unknown Item"
            data += gen.text(f"{item_name[:col_width]:<{col_width}} {item.quantity:>5}")
            if item.notes:
                data += gen.text(f"  Note: {item.notes}")
        
        data += gen.text("-" * (printer.paper_size // 2))
        data += gen.line_feed(5)
        data += gen.cut()
        return data

    def _format_billing_receipt(self, order: Any, printer: Printer) -> bytes:
        gen = ESCPOSGenerator
        data = gen.initialize()
        
        # Header
        data += gen.align('center')
        data += gen.font_size(2, 2)
        data += gen.text("RATALA POS") 
        data += gen.font_size(1, 1)
        data += gen.text("Thank you for visiting!")
        data += gen.line_feed(1)
        
        # Order Info
        data += gen.align('left')
        data += gen.text(f"Bill No: {order.order_number}")
        data += gen.text(f"Date: {order.created_at.strftime('%Y-%m-%d %H:%M')}")
        if order.table:
            data += gen.text(f"Table: {order.table.table_id}")
        if order.customer:
            data += gen.text(f"Customer: {order.customer.name}")
            
        data += gen.text("-" * (printer.paper_size // 2))
        
        # Items
        col_width = 20 if printer.paper_size == 80 else 12
        data += gen.bold(True)
        data += gen.text(f"{'Item':<{col_width}} {'Qty':>3} {'Price':>7} {'Total':>7}")
        data += gen.bold(False)
        
        for item in order.items:
            item_name = item.menu_item.name if (item.menu_item) else "Unknown"
            total = item.quantity * item.price
            data += gen.text(f"{item_name[:col_width]:<{col_width}} {item.quantity:>3} {item.price:>7.2f} {total:>7.2f}")
            
        data += gen.text("-" * (printer.paper_size // 2))
        
        # Totals
        data += gen.align('right')
        data += gen.text(f"Subtotal: {order.gross_amount:>10.2f}")
        if order.discount:
            data += gen.text(f"Discount: {order.discount:>10.2f}")
        
        data += gen.bold(True)
        data += gen.font_size(1, 2)
        data += gen.text(f"TOTAL: {order.total_amount:>10.2f}")
        data += gen.font_size(1, 1)
        data += gen.bold(False)
        
        data += gen.line_feed(2)
        data += gen.align('center')
        data += gen.text("Please visit again!")
        data += gen.line_feed(5)
        data += gen.cut()
        return data

    async def _send_to_printer(self, printer: Printer, content: bytes):
        if printer.connection_type == PrinterConnection.NETWORK:
            await self._send_network(printer.ip_address, printer.port, content)
        elif printer.connection_type == PrinterConnection.USB:
            logger.error("USB printing not implemented in this environment")
            # In a real desktop environment, we might use pyusb or similar
            raise NotImplementedError("USB printing not implemented")
        else:
            raise ValueError(f"Unsupported connection type: {printer.connection_type}")

    async def _send_network(self, ip: str, port: int, content: bytes):
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.settimeout(5)
                s.connect((ip, port))
                s.sendall(content)
        except Exception as e:
            logger.error(f"Network print error to {ip}:{port} : {str(e)}")
            raise
