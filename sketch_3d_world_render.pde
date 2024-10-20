float lookingX, lookingY;

void setup() {
  size(640, 360, P3D);
  fill(204);
  lookingX = 0;
  lookingY = 0;
}

void draw() {
  lights();
  background(0);
  
  // Change height of the camera with mouseY
  camera(30, 0, 220.0, // eyeX, eyeY, eyeZ
         mouseX, mouseY, 0.0, // centerX, centerY, centerZ
         0.0, 1.0, 0.0); // upX, upY, upZ
  
  noStroke();
  box(90);
  stroke(255);
  line(-100, 0, 0, 100, 0, 0);
  line(0, -100, 0, 0, 100, 0);
  line(0, 0, -100, 0, 0, 100);
}

void keyPressed() {
  if (key == 'A') {
    lookingX -= 1;
  }
}
