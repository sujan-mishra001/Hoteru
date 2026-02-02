"""
Excel generation utilities
"""
from io import BytesIO
import pandas as pd


def generate_excel_report(data, title="Report", columns=None, metadata=None):
    """Generate an Excel report from data with optional metadata header"""
    buffer = BytesIO()
    
    if isinstance(data, list) and len(data) > 0:
        if isinstance(data[0], dict):
            df = pd.DataFrame(data)
        else:
            if columns:
                df = pd.DataFrame(data, columns=columns)
            else:
                df = pd.DataFrame(data)
    else:
        df = pd.DataFrame()
    
    with pd.ExcelWriter(buffer, engine='openpyxl') as writer:
        if metadata:
            # Create a header dataframe
            header_data = []
            if metadata.get('branch_name'):
                header_data.append([metadata.get('branch_name').upper()])
            if metadata.get('branch_address'):
                header_data.append([metadata.get('branch_address')])
            if metadata.get('branch_phone') or metadata.get('branch_email'):
                line = []
                if metadata.get('branch_phone'): line.append(f"Tel: {metadata.get('branch_phone')}")
                if metadata.get('branch_email'): line.append(f"Email: {metadata.get('branch_email')}")
                header_data.append([" | ".join(line)])
            
            header_data.append([title.upper()])
            header_data.append([f"Report Period: {metadata.get('period', 'N/A')}"])
            header_data.append(["Generated on: " + pd.Timestamp.now().strftime('%Y-%m-%d %H:%M:%S')])
            header_data.append([""]) # Empty row for spacing
            
            header_df = pd.DataFrame(header_data)
            header_df.to_excel(writer, sheet_name=title[:31], index=False, header=False)
            df.to_excel(writer, sheet_name=title[:31], index=False, startrow=len(header_data))
        else:
            df.to_excel(writer, sheet_name=title[:31], index=False)
    
    buffer.seek(0)
    return buffer
