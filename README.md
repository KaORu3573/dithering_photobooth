# dithering_photobooth

This project now includes a browser version of the original Processing sketch in `camera.pde`.

## What `camera.pde` does

The sketch:

- opens the webcam
- reads each frame
- converts pixels to grayscale
- applies an 8x8 Bayer dithering threshold
- optionally remaps black/white output into duotone palettes
- saves frames on demand

That maps cleanly to the browser:

- `Capture` -> `navigator.mediaDevices.getUserMedia()`
- `draw()` -> `requestAnimationFrame()`
- `pixels[]` -> `CanvasRenderingContext2D.getImageData()`
- `saveFrame()` -> `canvas.toDataURL()` plus download

## Run the website

Because browsers block camera access on plain file URLs, serve the folder locally:

```powershell
python -m http.server 8000
```

Then open:

```text
http://localhost:8000
```

## Files

- `index.html`: page structure and controls
- `style.css`: layout and visual styling
- `script.js`: webcam access, Bayer dithering, palette mapping, capture/download
- `camera.pde`: original Processing reference

## Porting notes

The JavaScript version keeps the same Bayer matrix from the Processing sketch. The main algorithm is:

1. Draw the current webcam frame to an off-screen pixel buffer.
2. Convert each pixel to grayscale.
3. Look up a threshold from the Bayer matrix using `x % 8` and `y % 8`.
4. Output one of two colors based on the threshold result.
5. Paint the processed frame back to the canvas.

If you want the website to match the sketch even more closely, the next steps would be:

- add a countdown flow before capture
- save a strip of 3 or 4 photos instead of a single frame
- expose Floyd-Steinberg and Atkinson as filter options
- mirror the camera for a more natural selfie preview
