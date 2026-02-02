"""
Reports and export routes
"""
from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from typing import Optional

from sqlalchemy import func
from app.database import get_db
from app.dependencies import get_current_user
from app.models import Order, Product, Customer, User, Branch
from app.utils.pdf_generator import generate_pdf_report, generate_invoice_pdf
from app.utils.excel_generator import generate_excel_report

def get_branch_metadata(current_user, db):
    """Helper to get branch info for current session"""
    if current_user.current_branch_id:
        branch = db.query(Branch).filter(Branch.id == current_user.current_branch_id).first()
        if branch:
            return {
                "branch_name": branch.name,
                "branch_address": branch.address or branch.location,
                "branch_phone": branch.phone,
                "branch_email": branch.email
            }
    return None

router = APIRouter()


@router.get("/dashboard-summary")
async def get_dashboard_summary(
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get summarized data for the admin dashboard with optional date range"""
    from app.models import Table, Order
    from datetime import datetime, time, timedelta
    
    total_tables = db.query(Table).count()
    occupied_tables = db.query(Table).filter(Table.status == 'Occupied').count()
    occupancy = (occupied_tables / total_tables * 100) if total_tables > 0 else 0
    
    # Date filtering logic
    if start_date and end_date:
        try:
            start_dt = datetime.combine(datetime.strptime(start_date, '%Y-%m-%d').date(), time.min)
            end_dt = datetime.combine(datetime.strptime(end_date, '%Y-%m-%d').date(), time.max)
            orders_list = db.query(Order).filter(Order.created_at.between(start_dt, end_dt)).all()
            period_label = f"{start_date} to {end_date}"
            
            # For peak time data relative to the selected start date
            base_time = end_dt 
        except ValueError:
            # Fallback to 24h if date parsing fails
            base_time = datetime.now()
            start_dt = base_time - timedelta(hours=24)
            orders_list = db.query(Order).filter(Order.created_at >= start_dt).all()
            period_label = "Last 24 Hours"
    else:
        # Default to last 24 hours
        base_time = datetime.now()
        start_dt = base_time - timedelta(hours=24)
        orders_list = db.query(Order).filter(Order.created_at >= start_dt).all()
        period_label = "Last 24 Hours"
    
    # Sales breakdown
    sales_total = sum(order.net_amount or 0 for order in orders_list)
    paid_sales = sum(order.paid_amount or 0 for order in orders_list)
    credit_sales = sum(order.credit_amount or 0 for order in orders_list)
    discount = sum(order.discount or 0 for order in orders_list)
    
    # Order type breakdown
    dine_in_count = len([o for o in orders_list if o.order_type in ['Dine-In', 'Table']])
    takeaway_count = len([o for o in orders_list if o.order_type == 'Takeaway'])
    delivery_count = len([o for o in orders_list if o.order_type == 'Delivery'])

    # Outstanding revenue (all time credit)
    outstanding_revenue = sum(order.credit_amount or 0 for order in db.query(Order).all())

    # Top items with outstanding revenue
    from app.models import OrderItem, MenuItem
    from sqlalchemy import func
    
    credit_orders = [o.id for o in orders_list if o.credit_amount > 0]
    
    if credit_orders:
        top_items_query = db.query(
            MenuItem.name,
            func.sum(OrderItem.quantity * OrderItem.price).label('total_credit')
        ).join(
            OrderItem, MenuItem.id == OrderItem.menu_item_id
        ).filter(
            OrderItem.order_id.in_(credit_orders)
        ).group_by(
            MenuItem.id, MenuItem.name
        ).order_by(
            func.sum(OrderItem.quantity * OrderItem.price).desc()
        ).limit(3).all()
        
        top_outstanding_items = [
            {"name": item.name, "amount": float(item.total_credit)}
            for item in top_items_query
        ]
    else:
        top_outstanding_items = []
    
    # Top selling items
    if orders_list:
        order_ids = [o.id for o in orders_list]
        top_selling_query = db.query(
            MenuItem.name,
            func.sum(OrderItem.quantity).label('total_quantity'),
            func.sum(OrderItem.quantity * OrderItem.price).label('total_revenue')
        ).join(
            OrderItem, MenuItem.id == OrderItem.menu_item_id
        ).filter(
            OrderItem.order_id.in_(order_ids)
        ).group_by(
            MenuItem.id, MenuItem.name
        ).order_by(
            func.sum(OrderItem.quantity * OrderItem.price).desc()
        ).limit(3).all()
        
        top_selling_items = [
            {
                "name": item.name, 
                "quantity": int(item.total_quantity),
                "revenue": float(item.total_revenue)
            }
            for item in top_selling_query
        ]
    else:
        top_selling_items = []

    # Sales by area/floor
    from app.models import Floor
    sales_by_area = []
    floors = db.query(Floor).all()
    for floor in floors:
        floor_tables = [t.id for t in floor.tables] if floor.tables else []
        floor_sales = sum(
            order.net_amount or 0 
            for order in orders_list 
            if order.table_id in floor_tables
        )
        if floor_sales > 0:
            sales_by_area.append({
                "area": floor.name,
                "amount": floor_sales
            })
    
    # Peak time data - 24 hourly slots
    peak_time_data = [0] * 24
    hourly_sales = [0.0] * 24
    
    for order in orders_list:
        if order.created_at:
            # Calculate hour of the day (0-23)
            hour = order.created_at.hour
            peak_time_data[hour] += 1
            hourly_sales[hour] += (order.net_amount or 0)

    return {
        "occupancy": round(occupancy, 1),
        "total_tables": total_tables,
        "occupied_tables": occupied_tables,
        "sales_24h": sales_total,
        "paid_sales": paid_sales,
        "credit_sales": credit_sales,
        "discount": discount,
        "orders_24h": len(orders_list),
        "dine_in_count": dine_in_count,
        "takeaway_count": takeaway_count,
        "delivery_count": delivery_count,
        "outstanding_revenue": outstanding_revenue,
        "top_outstanding_items": top_outstanding_items,
        "top_selling_items": top_selling_items,
        "sales_by_area": sales_by_area,
        "peak_time_data": peak_time_data,
        "hourly_sales": hourly_sales,
        "period": period_label
    }




@router.get("/sales-summary")
async def get_sales_summary(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get sales summary"""
    orders = db.query(Order).filter(Order.status == 'Completed').all()
    total_sales = sum(order.total_amount or 0 for order in orders)
    total_orders = len(orders)
    return {
        "total_sales": total_sales,
        "total_orders": total_orders,
        "average_order_value": total_sales / total_orders if total_orders > 0 else 0
    }


@router.get("/day-book")
async def get_day_book(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get day book (all transactions for today)"""
    today = datetime.now().date()
    orders = db.query(Order).filter(Order.created_at >= today).all()
    return orders


@router.get("/export/pdf/{report_type}")
async def export_pdf(
    report_type: str,
    date: Optional[str] = None,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Export report as PDF with optional date filtering"""
    from datetime import datetime, time as dtime
    
    # Helper for date filtering
    query_start = None
    query_end = None
    
    if date:
        dt = datetime.strptime(date, '%Y-%m-%d')
        query_start = datetime.combine(dt.date(), dtime.min)
        query_end = datetime.combine(dt.date(), dtime.max)
    elif start_date and end_date:
        query_start = datetime.combine(datetime.strptime(start_date, '%Y-%m-%d').date(), dtime.min)
        query_end = datetime.combine(datetime.strptime(end_date, '%Y-%m-%d').date(), dtime.max)
    if report_type == "sales-summary":
        result = await get_sales_summary(db, current_user)
        data = [{"Metric": k, "Value": v} for k, v in result.items()]
        title = "Sales Summary"
    elif report_type == "day-book":
        orders = await get_day_book(db, current_user)
        data = [{"Order Number": o.order_number, "Total": o.total_amount, "Date": str(o.created_at)} for o in orders]
        title = "Day Book"
    elif report_type == "sales":
        # Get orders based on date selection
        if query_start and query_end:
            orders = db.query(Order).filter(Order.created_at.between(query_start, query_end)).all()
            title = f"Sales Report ({query_start.strftime('%Y-%m-%d')})" if date else f"Sales Report ({start_date} to {end_date})"
        else:
            # Default to last 24 hours
            last_24h = datetime.now() - timedelta(hours=24)
            orders = db.query(Order).filter(Order.created_at >= last_24h).all()
            title = "Daily Sales Report (Last 24h)"
        
        # Summary Metrics
        summary_metrics = {
            "Total Orders": len(orders),
            "Gross Sales": sum(o.total_amount or 0 for o in orders),
            "Total Discount": sum(o.discount or 0 for o in orders),
            "Net Sales": sum(o.net_amount or 0 for o in orders),
            "Paid Amount": sum(o.paid_amount or 0 for o in orders),
            "Credit Amount": sum(o.credit_amount or 0 for o in orders),
        }
        
        data = [{"Metric": k, "Value": f"Rs. {v:,.2f}" if isinstance(v, (int, float)) and k != "Total Orders" else v} for k, v in summary_metrics.items()]
        
        # Add payment type breakdown
        payment_breakdown = {}
        for o in orders:
            if o.paid_amount > 0:
                pt = o.payment_type or "Cash"
                payment_breakdown[pt] = payment_breakdown.get(pt, 0) + o.paid_amount
        
        if payment_breakdown:
            data.append({"Metric": "COLLECTION BREAKDOWN", "Value": "----------------"})
            for pt, amt in payment_breakdown.items():
                data.append({"Metric": pt, "Value": f"Rs. {amt:,.2f}"})

        # Add Order Type Breakdown
        type_breakdown = {}
        for o in orders:
            type_breakdown[o.order_type] = type_breakdown.get(o.order_type, 0) + 1
        
        if type_breakdown:
            data.append({"Metric": "ORDER TYPE BREAKDOWN", "Value": "----------------"})
            for ot, count in type_breakdown.items():
                data.append({"Metric": ot, "Value": str(count)})
    elif report_type == "inventory":
        products = db.query(Product).all()
        data = [{"Product": p.name, "Category": p.category or "-", "Stock": p.current_stock, "Unit": p.unit.name if p.unit else "-"} for p in products]
        title = "Inventory Consumption Report"
    elif report_type == "customers":
        customers = db.query(Customer).all()
        data = [{
            "Customer": c.name, 
            "Phone": c.phone or "-", 
            "Type": c.customer_type or "Regular",
            "Visits": c.total_visits or 0,
            "Total Spent": f"Rs. {c.total_spent:,.2f}" if c.total_spent else "Rs. 0.00",
            "Due": f"Rs. {c.due_amount:,.2f}" if c.due_amount else "Rs. 0.00"
        } for c in customers]
        title = "Customer Analytics & Loyalty Report"
    elif report_type == "staff":
        users = db.query(User).all()
        data = [{"Staff": u.full_name, "Role": u.role, "Username": u.username, "Status": "Active" if not u.disabled else "Disabled"} for u in users]
        title = "Staff Performance Report"
    else:
        raise HTTPException(status_code=404, detail="Report type not found")
    
    metadata = get_branch_metadata(current_user, db) or {}
    metadata['period'] = title.split('(')[-1].replace(')', '') if '(' in title else "Last 24 Hours"
    
    pdf_buffer = generate_pdf_report(data, title.split('(')[0].strip(), metadata=metadata)
    
    return StreamingResponse(
        pdf_buffer,
        media_type="application/pdf",
        headers={"Content-Disposition": f"attachment; filename={report_type}.pdf"}
    )


@router.get("/export/excel/{report_type}")
async def export_excel(
    report_type: str,
    date: Optional[str] = None,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Export report as Excel with optional date filtering"""
    from datetime import datetime, time as dtime
    
    query_start = None
    query_end = None
    
    if date:
        dt = datetime.strptime(date, '%Y-%m-%d')
        query_start = datetime.combine(dt.date(), dtime.min)
        query_end = datetime.combine(dt.date(), dtime.max)
    elif start_date and end_date:
        query_start = datetime.combine(datetime.strptime(start_date, '%Y-%m-%d').date(), dtime.min)
        query_end = datetime.combine(datetime.strptime(end_date, '%Y-%m-%d').date(), dtime.max)
    metadata = get_branch_metadata(current_user, db) or {}
    metadata['period'] = "Full Summary"
    
    if report_type == "sales-summary":
        result = await get_sales_summary(db, current_user)
        data = [{"Metric": k, "Value": v} for k, v in result.items()]
        excel_buffer = generate_excel_report(data, "Sales Summary", metadata=metadata)
    elif report_type == "day-book":
        orders = await get_day_book(db, current_user)
        data = [{"Order Number": o.order_number, "Total": o.total_amount, "Date": str(o.created_at)} for o in orders]
        excel_buffer = generate_excel_report(data, "Day Book", metadata=metadata)
    elif report_type == "sales":
        if query_start and query_end:
            orders = db.query(Order).filter(Order.created_at.between(query_start, query_end)).all()
            title = f"Sales Report ({query_start.strftime('%Y-%m-%d')})" if date else f"Sales Report ({start_date} to {end_date})"
        else:
            last_24h = datetime.now() - timedelta(hours=24)
            orders = db.query(Order).filter(Order.created_at >= last_24h).all()
            title = "Daily Sales Report (Last 24h)"
        
        data = []
        for o in orders:
            data.append({
                "Order #": o.order_number,
                "Type": o.order_type,
                "Status": o.status,
                "Gross": o.total_amount,
                "Discount": o.discount,
                "Net": o.net_amount,
                "Paid": o.paid_amount,
                "Credit": o.credit_amount,
                "Payment": o.payment_type or "-",
                "Date": o.created_at.strftime('%Y-%m-%d %H:%M') if o.created_at else "-"
            })
        
        if not data:
            data = [{"Message": "No sales record found for today"}]
            
        metadata = get_branch_metadata(current_user, db) or {}
        metadata['period'] = title.split('(')[-1].replace(')', '') if '(' in title else "Today"
        
        excel_buffer = generate_excel_report(data, title.split('(')[0].strip(), metadata=metadata)
    elif report_type == "inventory":
        products = db.query(Product).all()
        data = [{
            "Name": p.name,
            "Category": p.category or "-",
            "Current Stock": p.current_stock,
            "Min Stock": p.min_stock,
            "Unit": p.unit.name if p.unit else "-",
            "Status": p.status
        } for p in products]
        excel_buffer = generate_excel_report(data, "Inventory", metadata=metadata)
    elif report_type == "customers":
        customers = db.query(Customer).all()
        data = [{
            "Name": c.name,
            "Phone": c.phone or "-",
            "Email": c.email or "-",
            "Type": c.customer_type or "Regular",
            "Visits": c.total_visits or 0,
            "Total Spent": c.total_spent or 0,
            "Due Amount": c.due_amount or 0,
            "Created At": c.created_at.strftime('%Y-%m-%d') if c.created_at else "-"
        } for c in customers]
        excel_buffer = generate_excel_report(data, "Customer Analytics", metadata=metadata)
    elif report_type == "staff":
        users = db.query(User).all()
        data = [{
            "Name": u.full_name,
            "Username": u.username,
            "Email": u.email,
            "Role": u.role,
            "Organization": u.company_name or "-",
            "Status": "Active" if not u.disabled else "Disabled"
        } for u in users]
        excel_buffer = generate_excel_report(data, "Staff", metadata=metadata)
    else:
        raise HTTPException(status_code=404, detail="Report type not found")
    
    return StreamingResponse(
        excel_buffer,
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": f"attachment; filename={report_type}.xlsx"}
    )


@router.get("/orders/{order_id}/invoice")
async def get_order_invoice(
    order_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Generate invoice PDF for an order"""
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    
    order_data = {
        "order_number": order.order_number,
        "customer": {"name": order.customer.name if order.customer else None},
        "table": {"table_id": order.table.table_id if order.table else None},
        "items": [{"name": item.menu_item.name, "quantity": item.quantity, "price": item.price, "subtotal": item.subtotal} for item in order.items]
    }
    
    metadata = get_branch_metadata(current_user, db)
    pdf_buffer = generate_invoice_pdf(order_data, metadata=metadata)
    return StreamingResponse(
        pdf_buffer,
        media_type="application/pdf",
        headers={"Content-Disposition": f"attachment; filename=invoice_{order.order_number}.pdf"}
    )


@router.get("/export/all/excel")
async def export_all_excel(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Export all report data into a single multi-sheet Excel file"""
    import pandas as pd
    from io import BytesIO
    from datetime import datetime, timedelta
    
    buffer = BytesIO()
    last_24h = datetime.now() - timedelta(hours=24)
    
    # 1. Sales Data
    orders = db.query(Order).filter(Order.created_at >= last_24h).all()
    sales_df = pd.DataFrame([{
        "Order #": o.order_number,
        "Type": o.order_type,
        "Status": o.status,
        "Net Amount": o.net_amount,
        "Payment": o.payment_type or "Cash",
        "Time": o.created_at.strftime('%Y-%m-%d %H:%M') if o.created_at else "-"
    } for o in orders])
    
    # 2. Inventory Data
    products = db.query(Product).all()
    inventory_df = pd.DataFrame([{
        "Product": p.name,
        "Category": p.category or "-",
        "Stock": p.current_stock,
        "Min Stock": p.min_stock,
        "Status": p.status
    } for p in products])
    
    # 3. Customer Data
    customers = db.query(Customer).all()
    customers_df = pd.DataFrame([{
        "Name": c.name,
        "Phone": c.phone or "-",
        "Type": c.customer_type or "Regular",
        "Visits": c.total_visits or 0,
        "Total Spent": c.total_spent or 0,
        "Due": c.due_amount or 0
    } for c in customers])
    
    # 4. Staff Data
    users = db.query(User).all()
    staff_df = pd.DataFrame([{
        "Name": u.full_name,
        "Username": u.username,
        "Role": u.role,
        "Status": "Active" if not u.disabled else "Disabled"
    } for u in users])
    
    metadata = get_branch_metadata(current_user, db)
    header_rows = 0
    header_df = pd.DataFrame()
    
    if metadata:
        header_data = [
            [metadata.get('branch_name', '').upper()],
            [metadata.get('branch_address', '')],
            [f"Tel: {metadata.get('branch_phone', '')} | Email: {metadata.get('branch_email', '')}"],
            ["MASTER BUSINESS REPORT"],
            [f"Generated on: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"],
            [""] # Spacer
        ]
        header_df = pd.DataFrame(header_data)
        header_rows = len(header_data)

    # Ensure at least one sheet exists
    sheets = {
        'Sales Transactions': sales_df,
        'Inventory Levels': inventory_df,
        'Customer Database': customers_df,
        'Staff List': staff_df
    }
    
    with pd.ExcelWriter(buffer, engine='openpyxl') as writer:
        has_data = False
        for sheet_name, df in sheets.items():
            if not df.empty:
                has_data = True
                if not header_df.empty:
                    header_df.to_excel(writer, sheet_name=sheet_name, index=False, header=False)
                    df.to_excel(writer, sheet_name=sheet_name, index=False, startrow=header_rows)
                else:
                    df.to_excel(writer, sheet_name=sheet_name, index=False)
        
        if not has_data:
            pd.DataFrame([{"Message": "No data available"}]).to_excel(writer, sheet_name='No Data', index=False)
    
    buffer.seek(0)
    
    metadata = get_branch_metadata(current_user, db)
    prefix = metadata.get('branch_name').replace(' ', '_') if metadata and metadata.get('branch_name') else "Business"
    filename = f"{prefix}_Master_Report_{datetime.now().strftime('%Y%m%d_%H%M')}.xlsx"
    return StreamingResponse(
        buffer,
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )


@router.get("/sessions")
def get_sessions_report(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get all POS sessions for reporting"""
    from app.models.pos_session import POSSession
    from app.models.auth import User
    
    sessions = db.query(POSSession).order_by(POSSession.start_time.desc()).all()
    
    result = []
    for session in sessions:
        user = session.user
        result.append({
            "id": session.id,
            "user_id": session.user_id,
            "user": {
                "full_name": user.full_name if user else "Unknown",
                "role": user.role if user else "Staff"
            },
            "start_time": session.start_time.isoformat() if session.start_time else None,
            "end_time": session.end_time.isoformat() if session.end_time else None,
            "status": session.status,
            "opening_cash": session.opening_cash,
            "actual_cash": session.actual_cash,
            "expected_cash": session.expected_cash,
            "total_sales": session.total_sales,
            "total_orders": session.total_orders,
            "notes": session.notes
        })
    
    return result


@router.get("/export/sessions/pdf")
async def export_sessions_pdf(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Export all sessions as a PDF report"""
    from app.models.pos_session import POSSession
    
    sessions = db.query(POSSession).order_by(POSSession.start_time.desc()).all()
    
    data = []
    for s in sessions:
        user_name = s.user.full_name if s.user else "Unknown"
        duration = "-"
        if s.end_time and s.start_time:
            diff = s.end_time - s.start_time
            hours = diff.total_seconds() // 3600
            minutes = (diff.total_seconds() % 3600) // 60
            duration = f"{int(hours)}h {int(minutes)}m"
        elif s.status == "Open":
            duration = "Ongoing"

        data.append({
            "ID": f"#{s.id}",
            "Staff": user_name,
            "Start": s.start_time.strftime('%b %d, %H:%M') if s.start_time else "-",
            "Status": s.status,
            "Sales": f"Rs. {s.total_sales:,.2f}",
            "Orders": s.total_orders,
            "Duration": duration
        })
    
    metadata = get_branch_metadata(current_user, db)
    pdf_buffer = generate_pdf_report(data, "POS Shift Statistics Report", metadata=metadata)
    
    return StreamingResponse(
        pdf_buffer,
        media_type="application/pdf",
        headers={"Content-Disposition": "attachment; filename=session_report.pdf"}
    )


@router.get("/export/shift/{session_id}")
async def export_shift_report(
    session_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Generate a detailed single-shift report PDF"""
    from app.models.pos_session import POSSession
    from app.models import Order
    from io import BytesIO
    from reportlab.lib.pagesizes import A4
    from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
    from reportlab.lib.styles import getSampleStyleSheet
    from reportlab.lib import colors
    from reportlab.lib.units import inch
    
    session = db.query(POSSession).filter(POSSession.id == session_id).first()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
        
    buffer = BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=A4)
    elements = []
    styles = getSampleStyleSheet()
    
    # Title & Header
    metadata = get_branch_metadata(current_user, db)
    
    branch_name = "BUSINESS"
    if metadata:
        branch_name = metadata.get('branch_name') or "BUSINESS"
        elements.append(Paragraph(f"<b>{branch_name.upper()}</b>", styles['Normal']))
        if metadata.get('branch_address'):
            elements.append(Paragraph(metadata.get('branch_address'), styles['Normal']))
    else:
         elements.append(Paragraph(f"<b>{branch_name}</b>", styles['Normal']))

    elements.append(Paragraph(f"<b>{branch_name} Shift Report #{session.id}</b>", styles['Title']))
    elements.append(Paragraph(f"Staff: {session.user.full_name if session.user else 'Unknown'}", styles['Normal']))
    elements.append(Paragraph(f"Status: {session.status}", styles['Normal']))
    elements.append(Paragraph(f"Start: {session.start_time.strftime('%Y-%m-%d %H:%M')}", styles['Normal']))
    if session.end_time:
        elements.append(Paragraph(f"End: {session.end_time.strftime('%Y-%m-%d %H:%M')}", styles['Normal']))
    
    elements.append(Spacer(1, 20))
    
    # Financial Table
    data = [
        ["DESCRIPTION", "AMOUNT"],
        ["Opening Cash", f"Rs. {session.opening_cash:,.2f}"],
        ["Cash Sales", f"Rs. {session.cash_sales:,.2f}"],
        ["Online Sales", f"Rs. {session.online_sales:,.2f}"],
        ["Credit Sales", f"Rs. {session.credit_sales:,.2f}"],
        ["---", "---"],
        ["Expected Cash in Drawer", f"Rs. {session.expected_cash:,.2f}"],
        ["Actual Cash Reported", f"Rs. {session.actual_cash:,.2f}"],
        ["Difference", f"Rs. {(session.actual_cash - session.expected_cash):,.2f}"]
    ]
    
    t = Table(data, colWidths=[3*inch, 2*inch])
    t.setStyle(TableStyle([
        ('GRID', (0,0), (-1,-1), 1, colors.black),
        ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
        ('BACKGROUND', (0,0), (-1,0), colors.lightgrey),
        ('ALIGN', (1,0), (1,-1), 'RIGHT'),
    ]))
    elements.append(t)
    
    elements.append(Spacer(1, 20))
    elements.append(Paragraph(f"<b>Total Orders:</b> {session.total_orders}", styles['Normal']))
    elements.append(Paragraph(f"<b>Total Sales:</b> Rs. {session.total_sales:,.2f}", styles['Normal']))
    elements.append(Spacer(1, 10))
    elements.append(Paragraph(f"<b>Notes:</b> {session.notes or 'None'}", styles['Normal']))
    
    doc.build(elements)
    buffer.seek(0)
    
    return StreamingResponse(
        buffer,
        media_type="application/pdf",
        headers={"Content-Disposition": f"attachment; filename=shift_report_{session_id}.pdf"}
    )
