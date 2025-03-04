// Karl Gerstner,The golden sectionized column, 1956/57
// Chenrui Hu(recode), May, 2024
// Hangzhou, China

// Commissioned by Li Tingting, the translator of 'Designing Programmes'
// Programming for the Chinese version of 'Designing Programmes'

import controlP5.*;
import java.util.Collections;
import java.util.ArrayList;

ControlP5 cp5;
Slider displacementSlider, heightOrderSlider;
Toggle randomToggle;

final int[] HEIGHT_RATIOS = {6, 6, 3, 2, 1, 1};            // Height ratio sequence
final int[] WIDTH_RATIOS = {1, 1, 2, 3, 4, 8, 12, 20, 30}; // Width ratio sequence
final int[] COLOR_SEQUENCE = {0, 7, 2, 5, 4, 3, 6, 1, 8};  // Color sequence
final int UNIT_SIZE = 3;                                    // Size of the smallest unit

int cylinderRadius = 20;
int cylinderHeight = 800;

int totalWidth = 0;
ArrayList<Integer> randomizedHeightRatios;
boolean isRandomized = false;
PImage texture;

void setup() {
  size(800, 800, P3D);
  pixelDensity(2);
  
  // Calculate total width
  for (int ratio : WIDTH_RATIOS) {
    totalWidth += ratio;
  }

  cp5 = new ControlP5(this);
  
  displacementSlider = cp5.addSlider("displacement")
    .setPosition(20, 720)
    .setRange(0, 8)
    .setValue(50)
    .setColorCaptionLabel(color(50));

  heightOrderSlider = cp5.addSlider("heightOrder")
    .setPosition(20, 740)
    .setRange(0, HEIGHT_RATIOS.length - 1)
    .setValue(0)
    .setNumberOfTickMarks(HEIGHT_RATIOS.length)
    .snapToTickMarks(true)
    .setColorCaptionLabel(color(50))
    .setColorTickMark(color(0));

  randomToggle = cp5.addToggle("randomize")
    .setPosition(190, 740)
    .setValue(false)
    .setSize(20, 10)
    .setCaptionLabel("")
    .setColorCaptionLabel(color(50));
    
  cp5.addLabel("randomLabel")
    .setText("RANDOMIZE")
    .setPosition(215, 740)
    .setColor(color(50));

  randomizedHeightRatios = new ArrayList<Integer>();
  for (int ratio : HEIGHT_RATIOS) {
    randomizedHeightRatios.add(ratio);
  }
  
  // Create texture image
  texture = createImage(totalWidth * UNIT_SIZE, cylinderHeight, RGB);
}

void draw() {
  background(10);
  
  int heightOrder = int(heightOrderSlider.getValue());
  int displacementIndex = int(displacementSlider.getValue());
  
  handleRandomization();
  
  ArrayList<Integer> adjustedHeightRatios = adjustHeightOrder(heightOrder);

  texture.loadPixels();
  int yPos = 0;
  int baseOffset = 0;
  
  for (int i = 0; i < adjustedHeightRatios.size(); i++) {
    int currentHeight = adjustedHeightRatios.get(i) * UNIT_SIZE * 8;
    int layerOffset = baseOffset + i * displacementIndex * WIDTH_RATIOS[displacementIndex % WIDTH_RATIOS.length] * UNIT_SIZE;
    drawRects(WIDTH_RATIOS, COLOR_SEQUENCE, currentHeight, 0, yPos, totalWidth * UNIT_SIZE, layerOffset);
    yPos += currentHeight;
  }
  texture.updatePixels();

  // Draw 2D texture view
  hint(DISABLE_DEPTH_TEST);
  image(texture, 0, 0, width / 2, height);
  hint(ENABLE_DEPTH_TEST);

  // Draw 3D cylinder view
  draw3DCylinder();

  // Draw control interface
  cp5.draw();
}

// Handle randomization logic
void handleRandomization() {
  if (randomToggle.getValue() == 1.0 && !isRandomized) {
    Collections.shuffle(randomizedHeightRatios);
    isRandomized = true;
  } else if (randomToggle.getValue() == 0.0 && isRandomized) {
    randomizedHeightRatios.clear();
    for (int ratio : HEIGHT_RATIOS) {
      randomizedHeightRatios.add(ratio);
    }
    isRandomized = false;
  }
}

ArrayList<Integer> adjustHeightOrder(int heightOrder) {
  ArrayList<Integer> adjusted = new ArrayList<Integer>();
  for (int i = 0; i < HEIGHT_RATIOS.length; i++) {
    adjusted.add(randomizedHeightRatios.get((heightOrder + i) % HEIGHT_RATIOS.length));
  }
  return adjusted;
}

// Draw 3D cylinder
void draw3DCylinder() {
  pushMatrix();
  translate(width * 0.75, 80);
  rotateX(PI / 2);
  noStroke();

  textureMode(NORMAL);
  beginShape(QUAD_STRIP);
  texture(texture);
  
  float angle = 0;
  final float angleStep = TWO_PI / 50;
  for (int i = 0; i <= 50; i++) {
    float x = cos(angle) * cylinderRadius;
    float y = sin(angle) * cylinderRadius;
    float u = map(angle, 0, TWO_PI, 0, 1);

    vertex(x, y, 0, u, 0);
    vertex(x, y, -cylinderHeight, u, 1);
    
    angle += angleStep;
  }
  endShape();
  popMatrix();
}

// Draw rectangle sequence to texture
void drawRects(int[] ratios, int[] colors, int high, int x, int y, int totalWidth, int offset) {
  // Calculate total width units
  int tw = 0;
  for (int ratio : ratios) {
    tw += ratio;
  }

  int[] adjustedRatios = new int[ratios.length];
  int[] adjustedColors = new int[colors.length];

  int remainingOffset = offset % (tw * UNIT_SIZE);
  if (remainingOffset < 0) {
    remainingOffset += tw * UNIT_SIZE;
  }
  
  int startIndex = 0;
  for (int i = 0; i < ratios.length; i++) {
    if (remainingOffset >= ratios[i] * UNIT_SIZE) {
      remainingOffset -= ratios[i] * UNIT_SIZE;
      startIndex++;
    } else {
      break;
    }
  }

  // Adjust ratios and colors based on starting index
  for (int i = 0; i < ratios.length; i++) {
    int index = (startIndex + i) % ratios.length;
    adjustedRatios[i] = ratios[index];
    adjustedColors[i] = colors[index];
  }

  adjustedRatios[0] -= remainingOffset / UNIT_SIZE;

  for (int i = 0; i < adjustedRatios.length; i++) {
    int rectWidth = adjustedRatios[i] * UNIT_SIZE;
    int colorIndex = adjustedColors[i];
    color c = color(int(map(colorIndex, 0, 8, 255, 0)));
    
    fillRectInTexture(x, y, rectWidth, high, c);
    x += rectWidth;
  }

  if (remainingOffset > 0) {
    int rectWidth = remainingOffset;
    int colorIndex = adjustedColors[0];
    color c = color(int(map(colorIndex, 0, 8, 255, 0)));
    fillRectInTexture(x, y, rectWidth, high, c);
  }

  int grayValue = color(237);
  int grayRectHeight = 400;
  fillRectInTexture(0, y + high, totalWidth, grayRectHeight, grayValue);
}

void fillRectInTexture(int x, int y, int width, int height, color c) {
  for (int j = 0; j < height; j++) {
    for (int k = 0; k < width; k++) {
      int index = (y + j) * texture.width + x + k;
      if (index < texture.pixels.length && index >= 0) {
        texture.pixels[index] = c;
      }
    }
  }
}

// Chenrui Hu, May, 2024
// Hangzhou, China