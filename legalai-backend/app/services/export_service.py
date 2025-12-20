import os
from reportlab.pdfgen import canvas
from docx import Document
from flask import current_app
from ..models.drafts import Draft
from ..extensions import db

class ExportService:
    @staticmethod
    def export_txt(draft: Draft):
        return draft.content_text

    @staticmethod
    def export_pdf(draft: Draft):
        base = current_app.config["STORAGE_BASE"]
        os.makedirs(os.path.join(base, "drafts"), exist_ok=True)
        path = os.path.join(base, "drafts", f"draft_{draft.id}.pdf")

        c = canvas.Canvas(path)
        textobject = c.beginText(40, 800)
        for line in draft.content_text.splitlines():
            textobject.textLine(line)
        c.drawText(textobject)
        c.showPage()
        c.save()

        draft.pdf_path = os.path.relpath(path, base)
        db.session.commit()
        return path

    @staticmethod
    def export_docx(draft: Draft):
        base = current_app.config["STORAGE_BASE"]
        os.makedirs(os.path.join(base, "drafts"), exist_ok=True)
        path = os.path.join(base, "drafts", f"draft_{draft.id}.docx")

        doc = Document()
        for line in draft.content_text.splitlines():
            doc.add_paragraph(line)
        doc.save(path)

        draft.docx_path = os.path.relpath(path, base)
        db.session.commit()
        return path
