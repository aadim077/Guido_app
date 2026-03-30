from __future__ import annotations

from datetime import datetime
from io import BytesIO

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4, landscape
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas


def _safe_user_display_name(user) -> str:
    name = ""
    first = getattr(user, "first_name", "") or ""
    last = getattr(user, "last_name", "") or ""
    full = f"{first} {last}".strip()
    if full:
        name = full
    else:
        username = getattr(user, "username", "") or ""
        email = getattr(user, "email", "") or ""
        name = username.strip() or email.strip() or "Learner"
    return name


def _difficulty_label(difficulty: str) -> str:
    d = (difficulty or "").strip().lower()
    if not d:
        return "N/A"
    return d[:1].upper() + d[1:]


def generate_certificate_pdf(*, user, course, certificate_id: str) -> bytes:
    buffer = BytesIO()
    page_size = landscape(A4)
    c = canvas.Canvas(buffer, pagesize=page_size)

    width, height = page_size
    margin = 42

    navy = colors.HexColor("#0B1F3A")
    gold = colors.HexColor("#C99A2E")
    subtle = colors.HexColor("#F7F3E8")

    c.setFillColor(subtle)
    c.rect(0, 0, width, height, fill=1, stroke=0)

    outer_pad = 18
    inner_pad = 32

    c.setStrokeColor(gold)
    c.setLineWidth(3)
    c.rect(margin, margin, width - 2 * margin, height - 2 * margin, stroke=1, fill=0)

    c.setLineWidth(1.25)
    c.rect(
        margin + outer_pad,
        margin + outer_pad,
        width - 2 * (margin + outer_pad),
        height - 2 * (margin + outer_pad),
        stroke=1,
        fill=0,
    )

    title_y = height - margin - 92

    c.setFillColor(navy)
    c.setFont("Helvetica-Bold", 32)
    c.drawCentredString(width / 2, title_y, "CERTIFICATE OF COMPLETION")

    c.setStrokeColor(gold)
    c.setLineWidth(2)
    c.line(width * 0.22, title_y - 18, width * 0.78, title_y - 18)

    c.setFillColor(navy)
    c.setFont("Helvetica", 14)
    c.drawCentredString(width / 2, title_y - 56, "This is to certify that")

    name = _safe_user_display_name(user)
    c.setFont("Helvetica-Bold", 28)
    c.drawCentredString(width / 2, title_y - 98, name)

    c.setFont("Helvetica", 14)
    c.drawCentredString(width / 2, title_y - 134, "has successfully completed the course")

    course_title = getattr(course, "title", "") or "Course"
    c.setFont("Helvetica-Bold", 20)
    c.drawCentredString(width / 2, title_y - 170, course_title)

    difficulty = _difficulty_label(getattr(course, "difficulty", ""))
    c.setFont("Helvetica", 12)
    c.setFillColor(colors.HexColor("#2B3A55"))
    c.drawCentredString(width / 2, title_y - 196, f"Difficulty: {difficulty}")

    issued_at = datetime.utcnow().strftime("%B %d, %Y")
    bottom_y = margin + inner_pad

    c.setFillColor(colors.HexColor("#2B3A55"))
    c.setFont("Helvetica", 11)
    c.drawString(margin + inner_pad, bottom_y, f"Certificate ID: {certificate_id}")
    c.drawRightString(width - margin - inner_pad, bottom_y, f"Issued: {issued_at}")

    c.setFillColor(navy)
    c.setFont("Helvetica-Bold", 12)
    c.drawCentredString(width / 2, bottom_y, "Guido Learning Platform")

    c.setFillColor(gold)
    c.setFont("Helvetica-Bold", 16)
    c.drawCentredString(width / 2, margin + inner_pad + 26, "GUIDO")

    c.showPage()
    c.save()

    pdf_bytes = buffer.getvalue()
    buffer.close()
    return pdf_bytes

