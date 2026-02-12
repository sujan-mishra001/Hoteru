"""
PDF generation utilities - Clean Black & White Professional Format
"""
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer, KeepTogether
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch, mm
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT
from io import BytesIO
from datetime import datetime

# ========================================================================================
# GLOBAL STYLES & LAYOUT HELPER
# ========================================================================================

def _create_bw_styles():
    """Create professional black and white styles"""
    styles = getSampleStyleSheet()
    
    # Main Report Title (Centered, Large)
    title_style = ParagraphStyle(
        'ReportTitle',
        parent=styles['Heading1'],
        fontSize=24,
        leading=28,
        textColor=colors.HexColor("#1e293b"), # Dark slate, effectively black
        alignment=TA_CENTER,
        fontName='Helvetica-Bold',
        spaceAfter=30
    )
    
    # Section Headers (Like "Invoice Details", "Bill To")
    section_header_style = ParagraphStyle(
        'SectionHeader',
        parent=styles['Heading2'],
        fontSize=14,
        leading=18,
        textColor=colors.HexColor("#334155"),
        fontName='Helvetica-Bold',
        spaceBefore=15,
        spaceAfter=8
    )
    
    # Standard Text
    normal_style = ParagraphStyle(
        'CleanNormal',
        parent=styles['Normal'],
        fontSize=10,
        leading=14,
        textColor=colors.black,
        fontName='Helvetica'
    )

    # Table Header Text
    table_header_text = ParagraphStyle(
        'TableHeaderText',
        parent=styles['Normal'],
        fontSize=10,
        leading=12,
        textColor=colors.HexColor("#475569"),
        fontName='Helvetica-Bold',
        alignment=TA_CENTER
    )
    
    return {
        'title': title_style,
        'section': section_header_style,
        'normal': normal_style,
        'table_header': table_header_text
    }

def _create_info_block(title, data_dict, styles, col_widths=None):
    """
    Creates a formatted block like:
    **Title**
    | Label | Value |
    |-------|-------|
    """
    elements = []
    if title:
        elements.append(Paragraph(title, styles['section']))
    
    if not data_dict:
        return elements

    # Convert dict to table data
    table_data = []
    for label, value in data_dict.items():
        # Ensure value is string
        if value is None: value = "-"
        table_data.append([
            Paragraph(f"<b>{label}:</b>", styles['normal']), 
            Paragraph(str(value), styles['normal'])
        ])

    if not col_widths:
        col_widths = [2.0*inch, 4.5*inch]

    t = Table(table_data, colWidths=col_widths)
    t.setStyle(TableStyle([
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('TOPPADDING', (0, 0), (-1, -1), 3),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
        ('LEFTPADDING', (0, 0), (-1, -1), 5),
        ('RIGHTPADDING', (0, 0), (-1, -1), 5),
        ('LINEBELOW', (0, 0), (-1, -1), 0.5, colors.HexColor("#e2e8f0")), # Very subtle divider
        ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor("#f1f5f9")), # Box look? No, user wants simple.
        # Let's match the image: Outer border box
        ('BOX', (0, 0), (-1, -1), 0.5, colors.HexColor("#cbd5e1")),
        ('INNERGRID', (0, 0), (-1, -1), 0.5, colors.HexColor("#e2e8f0")),
        ('BACKGROUND', (0, 0), (0, -1), colors.HexColor("#f8fafc")) # Light grey for labels
    ]))
    
    elements.append(t)
    return elements


def _create_data_table(data_rows, header_row=None, col_widths=None):
    """
    Creates the main data table
    """
    table_data = []
    if header_row:
        table_data.append(header_row)
    
    table_data.extend(data_rows)
    
    if not table_data:
        return None

    # Calculate widths if not provided
    if not col_widths:
        # Default distribution for A4 (approx 7.5 inch width workable)
        count = len(table_data[0]) 
        col_widths = [7.2*inch / count] * count

    t = Table(table_data, colWidths=col_widths, repeatRows=1)
    
    # Clean B&W Style
    style_cmds = [
        # Header
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor("#f1f5f9")), # Very light grey header
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.HexColor("#334155")),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'), # Left align is usually cleaner than center for text
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, 0), 10),
        ('BOTTOMPADDING', (0, 0), (-1, 0), 10),
        ('TOPPADDING', (0, 0), (-1, 0), 10),
        
        # Body
        ('FONTNAME', (0, 1), (-1, -1), 'Helvetica'),
        ('FONTSIZE', (0, 1), (-1, -1), 9),
        ('TEXTCOLOR', (0, 1), (-1, -1), colors.black),
        ('BOTTOMPADDING', (0, 1), (-1, -1), 8),
        ('TOPPADDING', (0, 1), (-1, -1), 8),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor("#e2e8f0")), # Thin grey grid
        
        # Zebra striping? User asked for white/simple. 
        # "only black and white color" usually implies valid grayscale.
        # Let's stick to white background for body to be crisp.
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
    ]
    
    t.setStyle(TableStyle(style_cmds))
    return t

# ========================================================================================
# MAIN GENERATORS
# ========================================================================================

def generate_pdf_report(data, title="Report", columns=None, metadata=None):
    """
    Standard PDF Report Generator
    """
    buffer = BytesIO()
    doc = SimpleDocTemplate(
        buffer, 
        pagesize=A4, 
        rightMargin=40, 
        leftMargin=40, 
        topMargin=40, 
        bottomMargin=30
    )
    elements = []
    styles = _create_bw_styles()
    
    # 1. Main Title
    elements.append(Paragraph(title, styles['title']))
    
    # 2. Report Details Block
    report_details = {
        "Report Type": title,
        "Generated On": datetime.now().strftime('%B %d, %Y at %I:%M %p'),
        "Period": metadata.get('period', 'N/A') if metadata else 'N/A'
    }
    
    block1 = _create_info_block("Report Details", report_details, styles)
    elements.extend(block1)
    elements.append(Spacer(1, 20))
    
    # 3. Branch Details Block
    if metadata:
        branch_details = {
            "Branch Name": metadata.get('branch_name', ''),
            "Address": metadata.get('branch_address', ''),
            "Contact": f"{metadata.get('branch_phone', '')} | {metadata.get('branch_email', '')}"
        }
        # Filter empty
        branch_details = {k: v for k, v in branch_details.items() if v and v != " | "}
        
        block2 = _create_info_block("Branch Details", branch_details, styles)
        elements.extend(block2)
        elements.append(Spacer(1, 25))

    # 4. Data Table
    if data:
        # Prepare data
        rows = []
        header = None
        
        if columns:
            header = columns
        elif isinstance(data[0], dict):
            header = list(data[0].keys())
            
        for d in data:
            if isinstance(d, dict):
                rows.append([str(v) for v in d.values()])
            else:
                rows.append([str(v) for v in d])
        
        t = _create_data_table(rows, header_row=header)
        if t:
            elements.append(t)
    else:
        elements.append(Paragraph("No data available.", styles['normal']))
        
    doc.build(elements)
    buffer.seek(0)
    return buffer


def generate_multi_table_pdf_report(sections, title="Report", metadata=None):
    """
    Multi-section Report Generator
    """
    buffer = BytesIO()
    doc = SimpleDocTemplate(
        buffer, 
        pagesize=A4,
        rightMargin=40, 
        leftMargin=40, 
        topMargin=40, 
        bottomMargin=30
    )
    elements = []
    styles = _create_bw_styles()
    
    # 1. Title
    elements.append(Paragraph(title, styles['title']))

    # 2. Report Details
    report_details = {
        "Report Type": title,
        "Generated On": datetime.now().strftime('%B %d, %Y at %I:%M %p'),
        "Period": metadata.get('period', 'N/A') if metadata else 'N/A'
    }
    elements.extend(_create_info_block("Report Details", report_details, styles))
    elements.append(Spacer(1, 20))

    # 3. Branch Details
    if metadata:
        branch_details = {
            "Branch Name": metadata.get('branch_name', ''),
            "Address": metadata.get('branch_address', ''),
            "Contact": f"{metadata.get('branch_phone', '')} | {metadata.get('branch_email', '')}"
        }
        branch_details = {k: v for k, v in branch_details.items() if v and v != " | "}
        elements.extend(_create_info_block("Branch Details", branch_details, styles))
        elements.append(Spacer(1, 30))
        
    # 4. Sections
    for section in sections:
        # Section Title
        if section.get('title'):
            elements.append(Paragraph(section['title'], styles['section']))
            
        # Text Content
        if section.get('type') == 'text':
            elements.append(Paragraph(section.get('content', ''), styles['normal']))
            elements.append(Spacer(1, 15))
            continue
            
        # Table Content
        data = section.get('data', [])
        if not data:
            elements.append(Paragraph("No data.", styles['normal']))
            elements.append(Spacer(1, 15))
            continue
            
        header = section.get('columns')
        if not header and isinstance(data[0], dict):
            header = list(data[0].keys())
            
        rows = []
        for d in data:
            if isinstance(d, dict):
                rows.append([str(v) for v in d.values()])
            else:
                rows.append([str(v) for v in d])
        
        t = _create_data_table(rows, header_row=header)
        if t:
            elements.append(t)
        
        elements.append(Spacer(1, 25))
        
    doc.build(elements)
    buffer.seek(0)
    return buffer


def generate_invoice_pdf(order_data, metadata=None):
    """
    Invoice Specific PDF (Matching the style)
    """
    buffer = BytesIO()
    doc = SimpleDocTemplate(
        buffer, 
        pagesize=A4, 
        rightMargin=40, 
        leftMargin=40, 
        topMargin=40, 
        bottomMargin=30
    )
    elements = []
    styles = _create_bw_styles() # Reuse report styles for consistency
    
    # 1. Title
    elements.append(Paragraph("Billing Invoice", styles['title']))
    
    # 2. Invoice Details
    inv_details = {
        "Invoice Number": order_data.get('order_number', '-'),
        "Invoice Date": datetime.now().strftime('%B %d, %Y'),
        "Table": order_data.get('table', {}).get('table_id', '-')
    }
    
    elements.extend(_create_info_block("Invoice Details", inv_details, styles))
    elements.append(Spacer(1, 20))
    
    # 3. Bill To / Customer
    cust_name = order_data.get('customer', {}).get('name')
    cust_details = {
        "Customer Name": cust_name if cust_name else "Walk-in Customer",
        # Could add address/phone if available in data
    }
    
    elements.extend(_create_info_block("Bill To", cust_details, styles))
    elements.append(Spacer(1, 25))
    
    # 4. Items Table
    header = ['Description', 'Quantity', 'Rate', 'Amount']
    rows = []
    total = 0
    
    for item in order_data.get('items', []):
        subtotal = item.get('subtotal', 0)
        total += subtotal
        rows.append([
            item.get('name', '-'),
            str(item.get('quantity', 0)),
            f"{item.get('price', 0):,.2f}",
            f"{subtotal:,.2f}"
        ])
    
    # Add Total Row
    rows.append(['', '', 'Total', f"{total:,.2f}"])
    
    t = _create_data_table(rows, header_row=header)
    
    # Style override for Total row to make it look like a footer?
    # For now, just keep it clean in the table.
    
    if t:
        elements.append(t)
        
    # 5. Branch Footer (Optional, since we usually put branch info at top)
    # But user image shows Branch info is implicitly the "Issuer".
    # We can add a "Issued By" section at bottom or top.
    # The image has "Bill To" but doesn't explicitly show "Bill From".
    # We'll put "Issued By" at the bottom or top?
    # Standard invoices usually have "From" at top.
    # We'll add a "Issued By" block at the end using metadata.
    
    if metadata:
        elements.append(Spacer(1, 30))
        branch_details = {
            "Name": metadata.get('branch_name', ''),
            "Address": metadata.get('branch_address', ''),
            "Contact": metadata.get('branch_phone', '')
        }
        elements.extend(_create_info_block("Issued By", branch_details, styles))

    doc.build(elements)
    buffer.seek(0)
    return buffer
