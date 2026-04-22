const video = document.getElementById("sourceVideo");
const canvas = document.getElementById("previewCanvas");
const snapshotImage = document.getElementById("snapshotImage");
const startButton = document.getElementById("startButton");
const captureButton = document.getElementById("captureButton");
const downloadButton = document.getElementById("downloadButton");
const statusText = document.getElementById("status");

const ctx = canvas.getContext("2d", { willReadFrequently: true });

const bayerMatrix = [
  [0, 128, 32, 160, 8, 136, 40, 168],
  [192, 64, 224, 96, 200, 72, 232, 104],
  [48, 176, 16, 144, 56, 184, 24, 152],
  [240, 112, 208, 80, 248, 120, 216, 88],
  [12, 140, 44, 172, 4, 132, 36, 164],
  [204, 76, 236, 108, 196, 68, 228, 100],
  [60, 188, 28, 156, 52, 180, 20, 148],
  [252, 124, 220, 92, 244, 116, 212, 84]
];

let stream;
let animationFrameId;
let lastCaptureDataUrl = "";

startButton.addEventListener("click", startCamera);
captureButton.addEventListener("click", captureFrame);
downloadButton.addEventListener("click", downloadCapture);

function setStatus(message) {
  statusText.textContent = message;
}

async function startCamera() {
  if (stream) {
    return;
  }

  try {
    stream = await navigator.mediaDevices.getUserMedia({
      video: {
        width: { ideal: 1280 },
        height: { ideal: 960 },
        facingMode: "user"
      },
      audio: false
    });
    video.srcObject = stream;
    await video.play();
    if (video.videoWidth && video.videoHeight) {
      canvas.width = video.videoWidth;
      canvas.height = video.videoHeight;
    }
    captureButton.disabled = false;
    setStatus("Camera running. Live Bayer dithering active.");
    renderLoop();
  } catch (error) {
    console.error(error);
    setStatus("Camera access failed. Use HTTPS or localhost and allow webcam permission.");
  }
}

function renderLoop() {
  if (!stream) {
    return;
  }

  ctx.save();
  ctx.scale(-1, 1);
  ctx.drawImage(video, -canvas.width, 0, canvas.width, canvas.height);
  ctx.restore();
  const frame = ctx.getImageData(0, 0, canvas.width, canvas.height);
  ditherFrame(frame);
  ctx.putImageData(frame, 0, 0);

  animationFrameId = requestAnimationFrame(renderLoop);
}

function ditherFrame(frame) {
  const { data, width, height } = frame;

  for (let y = 0; y < height; y += 1) {
    for (let x = 0; x < width; x += 1) {
      const index = (y * width + x) * 4;
      const r = data[index];
      const g = data[index + 1];
      const b = data[index + 2];

      // Match the Processing sketch's grayscale-before-threshold behavior.
      const grey = 0.299 * r + 0.587 * g + 0.114 * b;
      const threshold = bayerMatrix[y % 8][x % 8];
      const tone = grey > threshold ? 255 : 0;

      data[index] = tone;
      data[index + 1] = tone;
      data[index + 2] = tone;
      data[index + 3] = 255;
    }
  }
}

function captureFrame() {
  lastCaptureDataUrl = canvas.toDataURL("image/png");
  snapshotImage.src = lastCaptureDataUrl;
  downloadButton.disabled = false;
  setStatus("Frame captured. Download the PNG when ready.");
}

function downloadCapture() {
  if (!lastCaptureDataUrl) {
    return;
  }

  const link = document.createElement("a");
  link.href = lastCaptureDataUrl;
  link.download = `dither-booth-${Date.now()}.png`;
  link.click();
}

window.addEventListener("beforeunload", () => {
  if (animationFrameId) {
    cancelAnimationFrame(animationFrameId);
  }
  if (stream) {
    for (const track of stream.getTracks()) {
      track.stop();
    }
  }
});
