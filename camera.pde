import processing.video.*;
float zoff = 0;
float scale = 0.02;
int frameCounter = 0;

Capture cam;

color colorA;
color colorB;
color colorC;
color colorD;
color colorE;
color colorF;

int[][] bayerMatrix = { //8x8
  {  0, 128,  32, 160,   8, 136,  40, 168 },
  { 192,  64, 224,  96, 200,  72, 232, 104 },
  {  48, 176,  16, 144,  56, 184,  24, 152 },
  { 240, 112, 208,  80, 248, 120, 216,  88 },
  {  12, 140,  44, 172,   4, 132,  36, 164 },
  { 204,  76, 236, 108, 196,  68, 228, 100 },
  {  60, 188,  28, 156,  52, 180,  20, 148 },
  { 252, 124, 220,  92, 244, 116, 212,  84 }
};


void setup() {
  size(640, 480);
  
    // blue/yellow tones
  colorA = color(2,65,166);
  colorB = color(250,182,47);
  // turquise/pink tones
  colorC = color(67,222,212);
  colorD = color(255,161,205);
   //  pink tones
  colorE = color(240,87,133);
  colorF = color(255,193,212);

  // this code sets up `cam` as a Capture device, using the first camera
  // on your computer.
  // if this doesn't work: speak to Tom
  String[] cameras = Capture.list();
  
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      println(cameras[i]);
    }
    
    // The camera can be initialized directly using an 
    // element from the array returned by list():
    cam = new Capture(this, 640,480,cameras[0], 30);
    cam.start();     
  }      
}

void draw() {
  // every frame, if the camera is ready, we update `cam` to have
  // the latest data from it
  if (cam.available() == true) {
    cam.read();
  }
  
  // this next line is for TESTING
  // once the image appears on screen, delete it, and uncomment the code below
  image(cam,0,0);
  
  // to draw the new image pixel-by-pixel:
  // the Capture object (cam) has a property "pixels" that works just like a screen.
  loadPixels();
  cam.loadPixels();
  for(int i = 0; i < cam.pixels.length; i++) {
    // convert pixel to greyscale
    float greyValue = red(pixels[i]);

    // threshold pixel to either black or white.
    float newPixelValue = 0;

    if (greyValue > 127) {
      newPixelValue = 255;
    }

    float error = greyValue - newPixelValue;

    pixels[i] = color(newPixelValue);

    // diffuse error onwards
    //diffuseError(i,error);
    //atkinsonDither(i,error);
    //fsDither(i, error);
    bayerDither(i, greyValue);

  }
  
  //filter
  for (int i = 0; i < pixels.length; i++){
    //pixels[i] = contrast(pixels[i], 200);
    //pixels[i] = duotone(pixels[i], colorE, colorF);
  }
  
  updatePixels();
  
  zoff += 0.02;
  //save frame every 60 frames (1 sec at 60fps)
  frameCounter++;
  if (frameCounter >= 30) {
    saveFrame("frames/frame-####.png");
    frameCounter = 0;
  }
  
}

void keyPressed() {
  // pressing S will save the current frame to disk
  if(key == 's') {
    saveFrame("frame-######.jpg");
  }
}

void diffuseError(int i, float error) {
  if (i < pixels.length-1) {
    float nextGreyValue = red(pixels[i+1]);
    pixels[i+1] = color(nextGreyValue + error);
  }
}

void fsDither(int i, float error) {
  // Floyd-Steinberg Dithering
  //
  // x is the current pixel:
  //
  //  .  x  7
  //  3  5  1
  //  (all /16)

  int[] offsets = {
    1, width-1, width, width+1
  };

  float[] ditherRatios = {
    7/16.0, 3/16.0, 5/16.0, 1/16.0
  };

  for (int j = 0; j < offsets.length; j++) {
    int neighbourIndex = i + offsets[j];
    if (neighbourIndex < pixels.length) {
      float neighbourGrey = red(pixels[neighbourIndex]);
      pixels[neighbourIndex] = color(neighbourGrey + (error*ditherRatios[j]));
    }
  }
}

void atkinsonDither(int i, float error) {
  // Atkinson Dithering
  //
  // x is the current pixel:
  //
  //  .  x  1  1
  //  1  1  1  .
  //  .  1  .  .
  //  (all / 8)


  int[] offsets = {
    1, 2, width-1, width, width+1, width*2
  };

  for (int j = 0; j < offsets.length; j++) {
    int neighbourIndex = i + offsets[j];
    if (neighbourIndex < pixels.length) {
      float neighbourGrey = red(pixels[neighbourIndex]);
      pixels[neighbourIndex] = color(neighbourGrey + (error/8.0));
    }
  }
}

void bayerDither(int pixelIndex, float greyValue){
  // calculate x and y position from pixel index
  int x = pixelIndex % width;
  int y = pixelIndex / width;

  int threshold = bayerMatrix[y % 8][x % 8];

  float newPixel = (greyValue > threshold) ? 255 : 0;
  pixels[pixelIndex] = color(newPixel);
}

color contrast (color pixel, float contrastAmount){
  float r = red(pixel);
  float g = green(pixel);
  float b = blue(pixel);
  
  float contrastFactor = (259*(contrastAmount+255)) / (255*(259-contrastAmount));
  
  r = (contrastFactor * (r - 128)) + 128;
  g = (contrastFactor * (g - 128)) + 128;
  b = (contrastFactor * (b - 128)) + 128;
  
  return color(r, g, b);
}

color duotone (color pixel, color colorA, color colorB){
  float tone = red(pixel);
  float lerpAmount = norm(tone, 0, 255);
  
  return lerpColor(colorA, colorB, lerpAmount);
}
