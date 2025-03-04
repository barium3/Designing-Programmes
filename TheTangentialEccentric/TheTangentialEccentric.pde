// Karl Gerstner,The Tangential Eccentric, 1956/57
// Chenrui Hu(recode), May, 2024
// Hangzhou, China

// Commissioned by Li Tingting, the translator of 'Designing Programmes'
// Programming for the Chinese version of 'Designing Programmes'

import controlP5.*;

ControlP5 cp5;
Slider layersSlider;
Slider rotationFactorSlider;

int layers = 10; // Number of layers
float initial_radius_large = 250; // Initial radius of large semicircle
float radius_ratio = 0.5; // Ratio of small semicircle radius to large semicircle radius
int rotation_factor = 2; // Rotation multiplier parameter
float base_rotation_angle = 5; // Base rotation angle in degrees
PVector prev_large_circle_center = new PVector(0, 0); // Center point of previous large circle

ArrayList<PGraphics> rectCanvases = new ArrayList<PGraphics>();
ArrayList<PGraphics> maskCanvases = new ArrayList<PGraphics>();

void setup() {
  size(700, 700, P2D);
  pixelDensity(2);

  cp5 = new ControlP5(this);

  layersSlider = cp5.addSlider("layers")
    .setPosition(10, 10)
    .setRange(2, 8)
    .setValue(5)
    .setSize(200, 20);

  rotationFactorSlider = cp5.addSlider("rotation_factor")
    .setPosition(10, 30)
    .setRange(0, 72)
    .setValue(4)
    .setSize(200, 20);
}

void draw() {
  background(245);
  
  fill(0);
  noStroke();
  ellipse(width/2, height/2, 500, 500);

  rectCanvases.clear();
  maskCanvases.clear();
  
  // Create new canvases for each layer
  for (int i = 0; i < layers; i++) {
    rectCanvases.add(createGraphics(width, height));
    maskCanvases.add(createGraphics(width, height));
  }
  
  // Calculate rotation angles for each layer
  float angles[] = new float[layers];
  for (int i = 0; i < layers; i++) {
    angles[i] = i * base_rotation_angle * rotation_factor;
  }

  prev_large_circle_center = new PVector(width / 2, height / 2);

  for (int layer = 0; layer < layers; layer++) {
    float radius_large = initial_radius_large * pow(radius_ratio, layer);
    float radius_small = radius_large * radius_ratio;
    
    PVector large_circle_center;
    if (layer > 0) {
      PVector offset = new PVector(
        2 * radius_large / 3 * sin(radians(angles[layer - 1])), 
        2 * radius_large / 3 * cos(radians(angles[layer - 1]))
      );
      large_circle_center = PVector.add(prev_large_circle_center, offset);
    } else {
      large_circle_center = new PVector(width / 2, height / 2);
    }
    
    drawRectanglesCanvas(layer, large_circle_center, angles[layer]);
    drawMaskCanvas(layer, large_circle_center, radius_large, radius_small, angles[layer]);
    rectCanvases.get(layer).mask(maskCanvases.get(layer));
    image(rectCanvases.get(layer), 0, 0);
    
    prev_large_circle_center = large_circle_center;
  }
}

// Draw rectangles with varying widths and grayscale colors
void drawRectanglesCanvas(int layer, PVector centerPoint, float angle) {
  PGraphics canvas = rectCanvases.get(layer);
  
  canvas.beginDraw();
  canvas.background(0, 0); 
  
  float rectWidth = 250; // Initial rectangle width
  
  canvas.pushMatrix();
  canvas.translate(centerPoint.x, centerPoint.y);
  canvas.rotate(-radians(angle));
  
  // Draw rectangles with decreasing width
  for (int i = 1; i < layers; i++) {
    float gray = map(i, 0, layers-1, 0, 255); 
    canvas.fill(gray);
    canvas.noStroke();
    canvas.rect(-rectWidth/2, -height/2, rectWidth, height);
    rectWidth = rectWidth / 2; 
  }
  
  canvas.popMatrix();
  canvas.endDraw();
}

// Draw mask shape with semicircles
void drawMaskCanvas(int layer, PVector centerPoint, float radiusLarge, float radiusSmall, float angle) {
  PGraphics canvas = maskCanvases.get(layer);
  
  canvas.beginDraw();
  canvas.background(0); 
  canvas.noStroke();
  canvas.fill(255); 
  
  ArrayList<PVector> pts = new ArrayList<PVector>();
  
  // Create points for large semicircle
  for (int i = 0; i <= 180; ++i) {
    float pointAngle = radians(i + angle);
    PVector point = new PVector(
      sin(pointAngle) * radiusLarge, 
      cos(pointAngle) * radiusLarge
    );
    point.add(centerPoint);
    pts.add(point);
  }
  
  // For all but the last layer, add small semicircle to create the cutout
  if (layer < layers - 1) {
    PVector smallCircleCenter = PVector.add(
      centerPoint, 
      new PVector(
        radiusLarge / 3 * sin(radians(angle)), 
        radiusLarge / 3 * cos(radians(angle))
      )
    );
    
    for (int i = 180; i >= 0; --i) {
      float pointAngle = radians(i + angle);
      PVector point = new PVector(
        sin(pointAngle) * radiusSmall, 
        cos(pointAngle) * radiusSmall
      );
      point.add(smallCircleCenter);
      pts.add(point);
    }
  }
  
  canvas.beginShape();
  for (PVector pt : pts) {
    canvas.vertex(pt.x, pt.y);
  }
  canvas.endShape(CLOSE);
  
  canvas.endDraw();
}

// Chenrui Hu, May, 2024
// Hangzhou, China
