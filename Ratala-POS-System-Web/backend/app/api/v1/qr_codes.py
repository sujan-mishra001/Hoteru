from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, Response
from sqlalchemy.orm import Session
from typing import List, Optional
import os
import uuid
from datetime import datetime
import qrcode
from io import BytesIO

from app.db.database import get_db
from app.models.qr_code import QRCode
from app.schemas.qr_code import QRCodeCreate, QRCodeUpdate, QRCodeResponse
from app.core.dependencies import get_current_user
from app.models.auth import User

router = APIRouter(prefix="/qr-codes", tags=["QR Codes"])

# Configure upload directory
UPLOAD_DIR = "uploads/qr_codes"
os.makedirs(UPLOAD_DIR, exist_ok=True)


@router.get("/", response_model=List[QRCodeResponse])
def get_qr_codes(
    branch_id: Optional[int] = None,
    is_active: Optional[bool] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get all QR codes with optional filters"""
    query = db.query(QRCode)
    
    if branch_id is not None:
        query = query.filter(QRCode.branch_id == branch_id)
    
    if is_active is not None:
        query = query.filter(QRCode.is_active == is_active)
    
    qr_codes = query.order_by(QRCode.display_order, QRCode.created_at.desc()).all()
    return qr_codes


@router.get("/generate-menu-qr")
async def generate_menu_qr(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Generate dynamic QR for the digital menu"""
    # Assuming frontend URL is needed. In local dev it could be localhost:3000
    # Ideally this would be in settings
    frontend_url = os.getenv("FRONTEND_URL", "http://localhost:3000")
    branch_id = current_user.current_branch_id or 1 # Fallback to 1
    
    # URL that the customer scans
    menu_url = f"{frontend_url}/digital-menu/{branch_id}"
    
    # Generate QR Code
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    qr.add_data(menu_url)
    qr.make(fit=True)

    img = qr.make_image(fill_color="black", back_color="white")
    
    # Save to buffer
    buf = BytesIO()
    img.save(buf)
    buf.seek(0)
    
    return Response(content=buf.getvalue(), media_type="image/png")


@router.get("/{qr_id}", response_model=QRCodeResponse)
def get_qr_code(
    qr_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get a specific QR code by ID"""
    qr_code = db.query(QRCode).filter(QRCode.id == qr_id).first()
    if not qr_code:
        raise HTTPException(status_code=404, detail="QR code not found")
    return qr_code


@router.post("/", response_model=QRCodeResponse)
async def create_qr_code(
    name: str = Form(...),
    image: UploadFile = File(...),
    is_active: bool = Form(True),
    display_order: int = Form(0),
    branch_id: Optional[int] = Form(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Create a new QR code with image upload"""
    print(f"DEBUG: Creating QR code - Name: {name}, Active: {is_active}, Order: {display_order}, Branch: {branch_id}")
    print(f"DEBUG: Image received: {image.filename}, Content-Type: {image.content_type}")
    
    # Validate file type
    if not image.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail=f"File must be an image. Received: {image.content_type}")
    
    # Generate unique filename
    file_extension = os.path.splitext(image.filename)[1]
    unique_filename = f"{uuid.uuid4()}{file_extension}"
    file_path = os.path.join(UPLOAD_DIR, unique_filename)
    
    # Save the uploaded file
    try:
        with open(file_path, "wb") as buffer:
            content = await image.read()
            buffer.write(content)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save image: {str(e)}")
    
    # Create QR code record
    image_url = f"/uploads/qr_codes/{unique_filename}"
    qr_code = QRCode(
        name=name,
        image_url=image_url,
        is_active=is_active,
        display_order=display_order,
        branch_id=branch_id
    )
    
    db.add(qr_code)
    db.commit()
    db.refresh(qr_code)
    
    return qr_code


@router.put("/{qr_id}", response_model=QRCodeResponse)
async def update_qr_code(
    qr_id: int,
    name: Optional[str] = Form(None),
    image: Optional[UploadFile] = File(None),
    is_active: Optional[bool] = Form(None),
    display_order: Optional[int] = Form(None),
    branch_id: Optional[int] = Form(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Update an existing QR code"""
    qr_code = db.query(QRCode).filter(QRCode.id == qr_id).first()
    if not qr_code:
        raise HTTPException(status_code=404, detail="QR code not found")
    
    # Update fields
    if name is not None:
        qr_code.name = name
    if is_active is not None:
        qr_code.is_active = is_active
    if display_order is not None:
        qr_code.display_order = display_order
    if branch_id is not None:
        qr_code.branch_id = branch_id
    
    # Handle image update
    if image:
        if not image.content_type.startswith("image/"):
            raise HTTPException(status_code=400, detail="File must be an image")
        
        # Delete old image
        old_image_path = qr_code.image_url.lstrip("/")
        if os.path.exists(old_image_path):
            try:
                os.remove(old_image_path)
            except:
                pass
        
        # Save new image
        file_extension = os.path.splitext(image.filename)[1]
        unique_filename = f"{uuid.uuid4()}{file_extension}"
        file_path = os.path.join(UPLOAD_DIR, unique_filename)
        
        try:
            with open(file_path, "wb") as buffer:
                content = await image.read()
                buffer.write(content)
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Failed to save image: {str(e)}")
        
        qr_code.image_url = f"/uploads/qr_codes/{unique_filename}"
    
    qr_code.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(qr_code)
    
    return qr_code


@router.delete("/{qr_id}")
def delete_qr_code(
    qr_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Delete a QR code"""
    qr_code = db.query(QRCode).filter(QRCode.id == qr_id).first()
    if not qr_code:
        raise HTTPException(status_code=404, detail="QR code not found")
    
    # Delete image file
    image_path = qr_code.image_url.lstrip("/")
    if os.path.exists(image_path):
        try:
            os.remove(image_path)
        except:
            pass
    
    db.delete(qr_code)
    db.commit()
    
    return {"message": "QR code deleted successfully"}

