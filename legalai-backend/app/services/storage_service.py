import os, uuid
from flask import current_app
from werkzeug.utils import secure_filename
from werkzeug.exceptions import BadRequest
import io
from PIL import Image, ImageOps

class StorageService:
    @staticmethod
    def save_file(file_storage, subdir: str):
        ext = (file_storage.filename or "").rsplit(".", 1)[-1].lower()
        if ext == "doc":
            ext = "docx"
        if ext not in current_app.config["ALLOWED_EXTS"]:
            raise BadRequest("File type not allowed")

        # Enforce size limit without loading full file in memory
        max_bytes = int(current_app.config["MAX_UPLOAD_MB"]) * 1024 * 1024
        stream = file_storage.stream
        pos = stream.tell()
        stream.seek(0, os.SEEK_END)
        size = stream.tell()
        stream.seek(pos, os.SEEK_SET)
        if size > max_bytes:
            raise BadRequest(f"File too large (max {current_app.config['MAX_UPLOAD_MB']}MB)")

        # Basic MIME / signature validation (lightweight, no extra deps)
        head = stream.read(16)
        stream.seek(pos, os.SEEK_SET)

        mimetype = (file_storage.mimetype or "").lower()

        def _is_pdf():
            return head.startswith(b"%PDF")

        def _is_png():
            return head.startswith(b"\x89PNG\r\n\x1a\n")

        def _is_jpeg():
            return head.startswith(b"\xff\xd8\xff")

        def _is_zip_based():
            # docx/xlsx are ZIP containers
            return head.startswith(b"PK\x03\x04")

        def _is_text_like():
            return (
                mimetype.startswith("text/")
                or mimetype in {"application/json", "application/xml", "image/svg+xml"}
            )

        ok = True
        if ext == "pdf":
            ok = _is_pdf()
        elif ext in {"png"}:
            ok = _is_png()
        elif ext in {"jpg", "jpeg"}:
            ok = _is_jpeg()
        elif ext in {"docx", "xlsx"}:
            ok = _is_zip_based()
        elif ext in {"txt", "csv", "tsv", "json", "svg"}:
            ok = _is_text_like()

        if not ok:
            raise BadRequest("File content does not match extension")

        base = current_app.config["STORAGE_BASE"]
        folder = os.path.join(base, subdir)
        os.makedirs(folder, exist_ok=True)

        fname = secure_filename(file_storage.filename)
        unique = f"{uuid.uuid4().hex}_{fname}"
        path = os.path.join(folder, unique)

        file_storage.save(path)
        return path

    @staticmethod
    def save_avatar(file_storage, subdir: str = "avatars") -> str:
        # Only JPG/PNG
        ext = (file_storage.filename or "").rsplit(".", 1)[-1].lower()
        if ext not in {"jpg", "jpeg", "png"}:
            raise BadRequest("Only JPG and PNG images are allowed")

        # Size limit: 5MB (do not rely on global MAX_UPLOAD_MB)
        max_bytes = 5 * 1024 * 1024
        stream = file_storage.stream
        pos = stream.tell()
        stream.seek(0, os.SEEK_END)
        size = stream.tell()
        stream.seek(pos, os.SEEK_SET)
        if size > max_bytes:
            raise BadRequest("Image too large (max 5MB)")

        # Decode + resize to 512x512 square
        try:
            stream.seek(0)
            img = Image.open(stream)
            img.verify()  # quick integrity check
            stream.seek(0)
            img = Image.open(stream)

            img = ImageOps.exif_transpose(img)
            img = img.convert("RGBA") if ext == "png" else img.convert("RGB")
            img = ImageOps.fit(img, (512, 512), method=Image.Resampling.LANCZOS)

            out = io.BytesIO()
            if ext == "png":
                img.save(out, format="PNG", optimize=True)
                out_ext = "png"
            else:
                img.save(out, format="JPEG", quality=85, optimize=True, progressive=True)
                out_ext = "jpg"

            out.seek(0)
        except Exception:
            raise BadRequest("Invalid image file")

        base = current_app.config["STORAGE_BASE"]
        folder = os.path.join(base, subdir)
        os.makedirs(folder, exist_ok=True)

        unique = f"{uuid.uuid4().hex}_avatar.{out_ext}"
        path = os.path.join(folder, unique)

        with open(path, "wb") as f:
            f.write(out.read())

        return path

    @staticmethod
    def public_path(abs_path: str) -> str:
        """
        Stores DB-safe relative path (no absolute server filesystem paths).
        """
        base = current_app.config["STORAGE_BASE"]
        try:
            rel = os.path.relpath(abs_path, base)
        except Exception:
            rel = abs_path
        return rel.replace("\\", "/")