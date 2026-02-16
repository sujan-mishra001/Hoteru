"""
Customer management routes with branch isolation
"""
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Body
from sqlalchemy.orm import Session
from sqlalchemy import or_

from app.db.database import get_db
from app.core.dependencies import get_current_user, get_branch_id
from app.models import Customer
from app.schemas import CustomerCreate, CustomerUpdate, CustomerResponse

router = APIRouter()


@router.get("", response_model=list[CustomerResponse])
async def get_customers(
    search: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Get all customers for the branch, optionally filtered by search (name or phone)"""
    query = db.query(Customer).filter(Customer.branch_id == branch_id)
    if search and search.strip():
        term = f"%{search.strip()}%"
        query = query.filter(or_(
            Customer.name.ilike(term),
            Customer.phone.ilike(term),
        ))
    customers = query.all()
    return customers


@router.post("", response_model=CustomerResponse)
async def create_customer(
    customer_data: CustomerCreate = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Create a new customer in the branch"""
    customer_dict = customer_data.dict()
    customer_dict['branch_id'] = branch_id
    
    new_customer = Customer(**customer_dict)
    db.add(new_customer)
    db.commit()
    db.refresh(new_customer)
    return new_customer


@router.get("/{customer_id}", response_model=CustomerResponse)
async def get_customer(
    customer_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Get customer by ID, filtered by branch"""
    customer = db.query(Customer).filter(
        Customer.id == customer_id,
        Customer.branch_id == branch_id
    ).first()
    
    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found or access denied")
    return customer


@router.put("/{customer_id}", response_model=CustomerResponse)
@router.patch("/{customer_id}", response_model=CustomerResponse)
async def update_customer(
    customer_id: int,
    customer_data: CustomerUpdate = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Update customer in the branch"""
    customer = db.query(Customer).filter(
        Customer.id == customer_id,
        Customer.branch_id == branch_id
    ).first()
    
    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found or access denied")
    
    update_data = customer_data.dict(exclude_unset=True)
    for key, value in update_data.items():
        if hasattr(customer, key) and key != 'branch_id':
            setattr(customer, key, value)
    
    db.commit()
    db.refresh(customer)
    return customer


@router.delete("/{customer_id}")
async def delete_customer(
    customer_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Delete customer in the branch"""
    customer = db.query(Customer).filter(
        Customer.id == customer_id,
        Customer.branch_id == branch_id
    ).first()
    
    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found or access denied")
    
    db.delete(customer)
    db.commit()
    return {"message": "Customer deleted successfully"}
