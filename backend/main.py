"""FastAPI application entry point."""

import os
import sys
import subprocess
import tempfile
from datetime import datetime
from pathlib import Path

from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse, FileResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

from parser import parse_material_excel
from generator import generate_delivery_note


def _resource_path(relative: str) -> str:
    """Get path to resource, works for dev and PyInstaller bundle."""
    if hasattr(sys, '_MEIPASS'):
        return os.path.join(sys._MEIPASS, relative)
    return os.path.join(os.path.dirname(__file__), relative)


app = FastAPI(title="送货单生成系统")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Serve frontend static files
STATIC_DIR = _resource_path("static")
DEV_STATIC_DIR = os.path.join(os.path.dirname(__file__), "..", "frontend", "dist")

# Use bundled static dir (PyInstaller) or dev build
if os.path.isdir(STATIC_DIR):
    _serve_dir = STATIC_DIR
elif os.path.isdir(DEV_STATIC_DIR):
    _serve_dir = DEV_STATIC_DIR
else:
    _serve_dir = None

if _serve_dir:
    assets_dir = os.path.join(_serve_dir, "assets")
    if os.path.isdir(assets_dir):
        app.mount("/assets", StaticFiles(directory=assets_dir), name="assets")

    @app.get("/")
    async def serve_index():
        return FileResponse(os.path.join(_serve_dir, "index.html"))

TEMPLATE_PATH = _resource_path(os.path.join("templates", "送货单(三联针式打印)1.xlsx"))


class CustomerInfo(BaseModel):
    name: str
    address: str = ""
    contact: str = ""
    phone: str = ""


class MaterialItem(BaseModel):
    material_name: str
    spec: str = ""
    quantity: float
    unit: str
    unit_price: float
    remark: str = ""


class GenerateRequest(BaseModel):
    customer: CustomerInfo
    materials: list[MaterialItem]


@app.post("/api/upload")
async def upload_material_excel(file: UploadFile = File(...)):
    """Upload and parse a material purchase Excel file."""
    with tempfile.NamedTemporaryFile(suffix=".xlsx", delete=False) as tmp:
        content = await file.read()
        tmp.write(content)
        tmp_path = tmp.name

    try:
        materials = parse_material_excel(tmp_path)
    finally:
        os.unlink(tmp_path)

    return {"materials": materials}


@app.post("/api/generate")
async def generate(request: GenerateRequest):
    """Generate delivery note Excel and save to Desktop."""
    customer = request.customer.model_dump()
    materials = [m.model_dump() for m in request.materials]

    output = generate_delivery_note(customer, materials, TEMPLATE_PATH)

    # Save to Desktop with timestamp
    desktop = Path.home() / "Desktop"
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"送货单_{timestamp}.xlsx"
    filepath = desktop / filename

    with open(filepath, "wb") as f:
        f.write(output.read())

    # Open in Finder/Explorer
    _reveal_file(str(filepath))

    return {"path": str(filepath), "filename": filename}


def _reveal_file(path: str):
    """Open file location in system file manager."""
    try:
        if sys.platform == "darwin":
            subprocess.Popen(["open", "-R", path])
        elif sys.platform == "win32":
            subprocess.Popen(["explorer", "/select,", path])
    except Exception:
        pass
