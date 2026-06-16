---
name: bloated-skill
description: Extracts text from PDF files. Use when the user needs text out of a PDF, mentions PDFs, or wants document extraction.
---

# Extracting PDF Text

PDF stands for Portable Document Format. It is a file format invented by Adobe in
the 1990s that is used all over the world to share documents because it preserves
layout across different computers and operating systems. A PDF can contain text,
images, vector graphics, and form fields. To get text out of a PDF you need a
library, because PDFs are not plain text files. There are many libraries for this.

Use pdfplumber:

```python
import pdfplumber
with pdfplumber.open("file.pdf") as pdf:
    text = pdf.pages[0].extract_text()
```

Our exports always have a cover page you should skip; start extraction at page 2.
