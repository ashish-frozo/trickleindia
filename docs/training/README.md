# Workflow training deck

`PoP-Workflow-Training.pptx` contains seven editable slides for the local demonstration and staff walkthrough. It does not represent signed-off training, approved translations, or production readiness. Pair it with `../USER_TRAINING.md` and `../REQUIREMENTS_CLOSURE.md`.

Generated using `scripts/build-training-deck.cjs`, PptxGenJS 4.0.1, Playwright 1.65.0, Sharp 0.35.5 and the local pptx skill's `html2pptx.js` conversion library. Set `HTML2PPTX` to that library and `NODE_PATH` to those development dependencies. The HTML source is generated deterministically by the script. The resulting deck was converted with LibreOffice and its thumbnail grid visually inspected; the grid is saved at `output/closure/training-thumbnails.jpg`.
