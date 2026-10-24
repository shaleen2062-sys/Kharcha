"""Run:  cd reader && pip install -r requirements-lite.txt httpx && OCR_ENGINE=tesseract OCR_LANGS=eng python -m unittest discover tests -v"""
import io
import os
import sys
import unittest

os.environ.setdefault("OCR_ENGINE", "tesseract")
os.environ.setdefault("OCR_LANGS", "eng")
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from fastapi.testclient import TestClient
from PIL import Image, ImageDraw, ImageFont

import server


def receipt_jpeg() -> bytes:
    """A printed-looking bill, drawn with whatever font the machine has."""
    font = None
    for path in ("/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf", "/usr/share/fonts/dejavu/DejaVuSansMono.ttf",
                 "C:/Windows/Fonts/consola.ttf", "/System/Library/Fonts/Menlo.ttc"):
        if os.path.exists(path):
            font = ImageFont.truetype(path, 30)
            break
    font = font or ImageFont.load_default()
    lines = ["BHAT BHATENI SUPERMARKET", "Kathmandu  PAN 123456789", "Date: 2026-10-03", "",
             "Rice 5kg            850.00", "Milk 1L x2          220.00", "Eggs tray           420.00",
             "Shampoo             380.00", "", "TOTAL              1870.00", "Thank you"]
    img = Image.new("RGB", (900, 60 + 48 * len(lines)), "white")
    d = ImageDraw.Draw(img)
    for i, t in enumerate(lines):
        d.text((30, 30 + 48 * i), t, fill="black", font=font)
    buf = io.BytesIO()
    img.save(buf, "JPEG", quality=92)
    return buf.getvalue()


class ServerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.client = TestClient(server.app)

    def setUp(self):
        server.TOKEN = ""

    def test_health_reports_models_and_ocr(self):
        r = self.client.get("/health")
        self.assertEqual(r.status_code, 200)
        self.assertTrue(r.json()["ok"], r.json())

    def test_reads_a_receipt_photo_into_the_contract_shape(self):
        r = self.client.post("/read", content=receipt_jpeg(), headers={"Content-Type": "image/jpeg"})
        self.assertEqual(r.status_code, 200, r.text)
        data = r.json()
        for key in ("total", "items", "confidence", "needs_review"):
            self.assertIn(key, data)
        self.assertIsInstance(data["items"], list)
        for item in data["items"]:
            self.assertEqual(set(["name", "qty", "price", "category"]) - set(item), set())

    def test_file_upload_endpoint_gives_the_same_shape(self):
        r = self.client.post("/read-file", files={"file": ("bill.jpg", receipt_jpeg(), "image/jpeg")})
        self.assertEqual(r.status_code, 200, r.text)
        self.assertIn("items", r.json())

    def test_rejects_non_images_and_empty_bodies(self):
        self.assertEqual(self.client.post("/read", content=b"hello").status_code, 422)
        self.assertEqual(self.client.post("/read", content=b"").status_code, 400)

    def test_token_is_enforced_when_set(self):
        server.TOKEN = "s3cret"
        self.assertEqual(self.client.post("/read", content=receipt_jpeg()).status_code, 401)
        ok = self.client.post("/read", content=receipt_jpeg(), headers={"Authorization": "Bearer s3cret"})
        self.assertEqual(ok.status_code, 200)


if __name__ == "__main__":
    unittest.main()
