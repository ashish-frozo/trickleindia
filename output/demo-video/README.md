# PoP 2.0 product walkthrough

This 16:9 walkthrough uses current local prototype captures from `output/nonaws/` and fictional records. The narration was generated with the Ainsley preset in Higgsfield Seed Audio. It describes the current prototype accurately: the AWS deployment, TUIF UAT, final language validation, and live AI services are not represented as complete.

## Files

- `PoP2-Product-Walkthrough.mp4` — rendered 77.7-second demo
- `index.html` — editable HyperFrames composition source
- `voiceover.txt` — narration script
- `media/ainsley-narration.mp3` — Higgsfield narration
- `media/*.png` — current app and portal captures used by the composition

## Re-render

With Node.js, FFmpeg, and HyperFrames CLI installed:

```sh
npx hyperframes lint output/demo-video
npx hyperframes render output/demo-video --output output/demo-video/PoP2-Product-Walkthrough.mp4 --fps 30 --quality standard --workers 1
```

The source screenshots are available in `output/nonaws/`. All data displayed in them is fictional prototype data.
