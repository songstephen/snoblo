// Project 2: Tooling
// SnoBlo by Stephen Song (ssong73)

import ddf.minim.spi.*;
import ddf.minim.signals.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;
import gab.opencv.*;
import processing.video.*;
import java.awt.*;

// video
Capture video;
OpenCV opencv;
String mouth_cascade = "haarcascade_mcs_mouth.xml";

// audio
Minim minim;
AudioInput in;
int time;

// fog
PGraphics canvas;
Rectangle bottomFace;

// control
boolean titleScreen = true;
boolean debug = false;

// runs once on startup
void setup() {
  size(640, 480);

  // initialize computer vision plugin
  video = new Capture(this, 640/2, 480/2);
  opencv = new OpenCV(this, 640/2, 480/2);
  opencv.loadCascade(mouth_cascade);  
  video.start();

  // initialize fog canvas
  canvas = createGraphics(width, height);
  canvas.beginDraw();
  canvas.background(0,128);
  tint(255, 128);
  canvas.smooth();
  canvas.noStroke();
  canvas.endDraw();
  
  // initalize microphone input
  minim = new Minim(this);
  in = minim.getLineIn(Minim.MONO, 512);
  in.setGain(0);
  if (debug) {
    minim.debugOn();
  }

  // draw title screen text
  fill(50);
  textAlign(CENTER);
  textSize(32);
  text("SnoBlo", width / 2, 100);
  textSize(24);
  text("By Stephen Song", width / 2, 140);
  textSize(14);
  text("Instructions:\n" +
    "Blow into the microphone to fog the screen.\n" +
    "Fog will form where your mouth is.\n" +
    "Click and drag the mouse to draw on the fog.\n" +
    "Press 'r' to clear the canvas again.", width / 2, 180); 
  textSize(24);
  text("Press Enter to begin!", width / 2, 320);
  
}

// loop
void draw() {
  if (!titleScreen) {
    scale(2);
    displayVideo();
    detectMouth();
    drawFog();
  }
}

// flip and display webcam input
void displayVideo() {
  pushMatrix();
  scale(-1.0, 1.0);
  image(video, -video.width, 0);
  opencv.loadImage(video);
  popMatrix();
}

// detect (with about 80% confidence) the user's mouth
// mouth-like objects like eyes, noses, and necks may be detected
void detectMouth() {
  Rectangle[] faces = opencv.detect();
  if (faces.length > 0) {
    bottomFace = faces[0];
    for (int i = 0; i < faces.length; i++) {
      if (faces[i].y > bottomFace.y) {
        bottomFace = faces[i]; 
      }
    }
  }
}

// process the drawing of fog
void drawFog() {
  image(canvas, 0, 0);
  canvas.beginDraw();
  canvas.smooth();
  canvas.noStroke();
  canvas.filter(BLUR, 1);
  
  // get the average microphone input
  float mic = 0;
  for(int i = 0; i < in.bufferSize() - 1; i++) {
    if (abs(in.mix.get(i)) > mic ) {
      mic = abs(in.mix.get(i));
    }
  }
  mic *= 50;

  // manage qualifying microphone input
  if (mic > 1.0) {
    if (bottomFace != null) {
      if (time == 0) {
        time = millis();
      }
      if (millis() - time > 100) { // to minimize sound artifacts
        canvas.fill(255,200);
        canvas.blendMode(ADD);
        canvas.ellipse(640/2 - bottomFace.x - bottomFace.width / 2,
          bottomFace.y + bottomFace.height / 2, bottomFace.width, bottomFace.width); 
      }
    }
  } else {
    time = 0;
  }

  // random snow particles
  canvas.fill(255,150 + random(50));
  float snowSize = random(10);
  canvas.ellipse(random(width),random(height),snowSize,snowSize);
  canvas.endDraw();

  // draws a bounding box around the detected mouth
  if (debug) {
    if (bottomFace != null) {
      noFill();
      stroke(0, 255, 0);
      rect(640/2 - bottomFace.x - bottomFace.width, bottomFace.y,
        bottomFace.width, bottomFace.height);
    }
  }
}

// erase some fog
void mouseDragged() {
  if (mouseButton == LEFT) {
    canvas.beginDraw();
    canvas.fill(0,255);
    canvas.blendMode(SUBTRACT);
    canvas.ellipse(mouseX / 2, mouseY / 2, 15, 15);
    canvas.endDraw();
  }
}

// keyboard control
void keyPressed() {
  if (key == 'r' || key == 'R') {
    canvas.clear();
  }
  if (key == ENTER && titleScreen) {
    titleScreen = false;
  }
}

// always close Minim audio classes when you are done with them
void stop() {
  in.close();
  minim.stop(); 
  super.stop();
}

// not sure what this does, makes the video work though
void captureEvent(Capture c) {
  c.read();
}
