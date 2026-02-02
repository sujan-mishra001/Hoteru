"""
PDF generation utilities
"""
from reportlab.lib import colors
from reportlab.lib.pagesizes import letter, A4
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib.units import inch
from io import BytesIO
from datetime import datetime


def generate_pdf_report(data, title="Report", columns=None, metadata=None):
    """Generate a premium PDF report from data"""
    buffer = BytesIO()
    # Use landscape for wider tables if needed
    doc = SimpleDocTemplate(buffer, pagesize=A4, rightMargin=30, leftMargin=30, topMargin=30, bottomMargin=18)
    elements = []
    styles = getSampleStyleSheet()
    
    # Custom Styles
    from reportlab.lib.styles import ParagraphStyle
    header_style = ParagraphStyle(
        'HeaderStyle',
        parent=styles['Heading1'],
        fontSize=18,
        textColor=colors.HexColor("#FF8C00"),
        spaceAfter=6,
        alignment=1 # Center
    )
    
    subheader_style = ParagraphStyle(
        'SubHeaderStyle',
        parent=styles['Normal'],
        fontSize=10,
        textColor=colors.grey,
        spaceAfter=12,
        alignment=1 # Center
    )

    branch_info_style = ParagraphStyle(
        'BranchInfoStyle',
        parent=styles['Normal'],
        fontSize=12,
        textColor=colors.HexColor("#1e293b"),
        spaceAfter=4,
        alignment=1 # Center
    )
    
    # Title & Header
    elements.append(Paragraph(title.upper(), header_style))

    # Branch/App Info
    if metadata:
        branch_name = metadata.get('branch_name')
        branch_address = metadata.get('branch_address')
        branch_phone = metadata.get('branch_phone')
        branch_email = metadata.get('branch_email')

        if branch_name:
            elements.append(Paragraph(f"<b>{branch_name.upper()}</b>", branch_info_style))
        
        if branch_address:
            elements.append(Paragraph(branch_address, subheader_style))
        
        contact_info = []
        if branch_phone:
            contact_info.append(f"Tel: {branch_phone}")
        if branch_email:
            contact_info.append(f"Email: {branch_email}")
        
        if contact_info:
            elements.append(Paragraph(" | ".join(contact_info), subheader_style))
    
    elements.append(Paragraph(f"Report Period: {metadata.get('period', 'N/A')}" if metadata else "", subheader_style))
    elements.append(Paragraph(f"Generated on: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}", subheader_style))
    elements.append(Spacer(1, 0.3*inch))
    
    # Table Styling
    if data and len(data) > 0:
        table_data = []
        if columns:
            table_data.append(columns)
        else:
            if isinstance(data[0], dict):
                table_data.append(list(data[0].keys()))
        
        for row in data:
            if isinstance(row, dict):
                table_data.append([str(v) for v in row.values()])
            else:
                table_data.append([str(v) for v in row])
        
        # Determine column widths based on available width
        available_width = doc.width
        col_count = len(table_data[0])
        col_widths = [available_width / col_count] * col_count
        
        table = Table(table_data, colWidths=col_widths)
        table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor("#FF8C00")),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 10),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 10),
            ('TOPPADDING', (0, 0), (-1, 0), 10),
            ('BACKGROUND', (0, 1), (-1, -1), colors.white),
            ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor("#f9fafb")]),
            ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor("#e5e7eb")),
            ('FONTSIZE', (0, 1), (-1, -1), 9),
            ('BOTTOMPADDING', (0, 1), (-1, -1), 8),
            ('TOPPADDING', (0, 1), (-1, -1), 8),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ]))
        elements.append(table)
    
    # Footer
    elements.append(Spacer(1, 0.5*inch))
    elements.append(Paragraph("Confidential - For Internal Use Only", subheader_style))
    
    doc.build(elements)
    buffer.seek(0)
    return buffer


def generate_invoice_pdf(order_data, metadata=None):
    """Generate an invoice PDF for an order"""
    buffer = BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=letter)
    elements = []
    styles = getSampleStyleSheet()

    header_style = styles['Title']
    subheader_style = styles['Normal']
    
    # Invoice Header
    if metadata:
        branch_name = metadata.get('branch_name')
        branch_address = metadata.get('branch_address')
        branch_phone = metadata.get('branch_phone')

        if branch_name:
            elements.append(Paragraph(f"<b>{branch_name.upper()}</b>", header_style))
        if branch_address:
            elements.append(Paragraph(branch_address, subheader_style))
        if branch_phone:
            elements.append(Paragraph(f"Tel: {branch_phone}", subheader_style))
    else:
        elements.append(Paragraph("<b>TAX INVOICE</b>", header_style))

    elements.append(Paragraph("INVOICE", styles['Title']))
    elements.append(Spacer(1, 0.3*inch))
    
    # Invoice Details
    invoice_data = [
        ['Invoice Number:', order_data.get('order_number', 'N/A')],
        ['Date:', datetime.now().strftime('%Y-%m-%d')],
        ['Customer:', order_data.get('customer', {}).get('name', 'N/A')],
        ['Table:', order_data.get('table', {}).get('table_id', 'N/A')],
    ]
    
    invoice_table = Table(invoice_data, colWidths=[2*inch, 4*inch])
    invoice_table.setStyle(TableStyle([
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 12),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 12),
    ]))
    elements.append(invoice_table)
    elements.append(Spacer(1, 0.3*inch))
    
    # Items Table
    items_data = [['Item', 'Quantity', 'Price', 'Total']]
    total = 0
    for item in order_data.get('items', []):
        items_data.append([
            item.get('name', 'N/A'),
            str(item.get('quantity', 0)),
            f"रू {item.get('price', 0)}",
            f"रू {item.get('subtotal', 0)}"
        ])
        total += item.get('subtotal', 0)
    
    items_data.append(['', '', 'Total:', f"रू {total}"])
    
    items_table = Table(items_data, colWidths=[3*inch, 1*inch, 1*inch, 1*inch])
    items_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
        ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 12),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 12),
        ('BACKGROUND', (0, 1), (-1, -2), colors.beige),
        ('FONTNAME', (0, -1), (-1, -1), 'Helvetica-Bold'),
        ('GRID', (0, 0), (-1, -1), 1, colors.black)
    ]))
    elements.append(items_table)
    
    doc.build(elements)
    buffer.seek(0)
    return buffer
