from fastapi import APIRouter

router = APIRouter()

@router.get("/list")
async def list_files():
    """List shared files"""
    return {"files": []}

@router.delete("/{file_path}")
async def delete_file(file_path: str):
    """Delete a specific file"""
    return {"message": "File deletion not implemented yet"}