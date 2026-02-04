from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.core.dependencies import get_current_user
from app.models.printer import Printer as PrinterModel
from app.schemas.printer import Printer, PrinterCreate, PrinterUpdate

router = APIRouter()

@router.get("/", response_model=List[Printer])
def read_printers(
    db: Session = Depends(get_db),
    skip: int = 0,
    limit: int = 100,
    current_user: Any = Depends(get_current_user),
) -> Any:
    """
    Retrieve printers for the current user's branch.
    """
    branch_id = current_user.current_branch_id
    query = db.query(PrinterModel)
    if branch_id:
        query = query.filter(PrinterModel.branch_id == branch_id)
    
    printers = query.offset(skip).limit(limit).all()
    return printers

@router.post("/", response_model=Printer)
def create_printer(
    *,
    db: Session = Depends(get_db),
    printer_in: PrinterCreate,
    current_user: Any = Depends(get_current_user),
) -> Any:
    """
    Create new printer.
    """
    printer_dict = printer_in.dict()
    printer_dict["branch_id"] = current_user.current_branch_id
    printer_dict["organization_id"] = current_user.organization_id
    
    printer = PrinterModel(**printer_dict)
    db.add(printer)
    db.commit()
    db.refresh(printer)
    return printer

@router.put("/{id}", response_model=Printer)
def update_printer(
    *,
    db: Session = Depends(get_db),
    id: int,
    printer_in: PrinterUpdate,
    current_user: Any = Depends(get_current_user),
) -> Any:
    """
    Update a printer.
    """
    printer = db.query(PrinterModel).filter(PrinterModel.id == id).first()
    if not printer:
        raise HTTPException(status_code=404, detail="Printer not found")
    
    update_data = printer_in.dict(exclude_unset=True)
    for field in update_data:
        setattr(printer, field, update_data[field])
    
    db.add(printer)
    db.commit()
    db.refresh(printer)
    return printer

@router.get("/{id}", response_model=Printer)
def read_printer(
    *,
    db: Session = Depends(get_db),
    id: int,
    current_user: Any = Depends(get_current_user),
) -> Any:
    """
    Get printer by ID.
    """
    printer = db.query(PrinterModel).filter(PrinterModel.id == id).first()
    if not printer:
        raise HTTPException(status_code=404, detail="Printer not found")
    return printer

@router.delete("/{id}", response_model=Printer)
def delete_printer(
    *,
    db: Session = Depends(get_db),
    id: int,
    current_user: Any = Depends(get_current_user),
) -> Any:
    """
    Delete a printer.
    """
    printer = db.query(PrinterModel).filter(PrinterModel.id == id).first()
    if not printer:
        raise HTTPException(status_code=404, detail="Printer not found")
    db.delete(printer)
    db.commit()
    return printer
