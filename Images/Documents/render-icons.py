#!/usr/bin/python3
"""Render the SVG document icons to GNUstep-compatible 48px RGBA TIFFs.

Requires Python 3, PyGObject, librsvg, and Pillow. Normal builds use
checked-in TIFFs and do not need these tools.
"""
from io import BytesIO
from pathlib import Path

import gi
from PIL import Image

gi.require_version("Rsvg", "2.0")
from gi.repository import Rsvg

for source in sorted(Path(__file__).resolve().parent.glob("*.svg")):
    handle = Rsvg.Handle.new_from_file(str(source))
    success, data = handle.get_pixbuf().save_to_bufferv("png", [], [])
    if not success:
        raise RuntimeError("Could not render " + str(source))
    Image.open(BytesIO(data)).convert("RGBA").save(
        source.with_suffix(".tiff"), compression="tiff_lzw")
