int cols, rows;
int scale = 10;  // Size of each grid square
int w = 1400;  // Width of the plane
int h = 1000;  // Height of the plane
int centerX, centerY;  // Center of the screen

float[][] terrain;  // Array to hold terrain height values

float posX, posY;  // Camera position
float speed = 0;   // Speed based on mouse distance from center
float maxSpeed = 100;  // Maximum movement speed

void setup() {
    fullScreen(P3D);
    noCursor();
    //size(1280, 720, P3D);
    cols = w / scale;
    rows = h / scale;
    terrain = new float[cols][rows];
    posX = 0;
    posY = 0;
    centerX = displayWidth / 4;  // Center of the screen
    centerY = displayHeight / 4;
    textSize(16);  // Set the text size for speed display
}

void draw() {
    background(0);
    stroke(255);
    noFill();

    // Calculate the direction and speed based on the mouse position
    float dirX = (mouseX - centerX) / float(centerX);  // Horizontal direction (-1 to 1)
    float dirY = (mouseY - centerY) / float(centerY);  // Vertical direction (-1 to 1)

    // Calculate the speed based on the distance from the center, capped by maxSpeed
    speed = dist(mouseX, mouseY, centerX, centerY) / float(centerX) * maxSpeed;

    // Move the terrain based on direction and speed
    posX += dirX * speed;
    posY += dirY * speed;

    // Generate Perlin noise for each point in the grid
    float yoff = posY * 0.01;  // Varying offset in the y-direction for noise
    for (int y = 0; y < rows; y++) {
        float xoff = posX * 0.01;  // Varying offset in the x-direction for noise
        for (int x = 0; x < cols; x++) {
            // Use noise() function to determine the height at each point
            terrain[x][y] = map(noise(xoff, yoff), 0, 1, -100, 100);
            xoff += 0.1;  // Adjust the x-offset increment
        }
        yoff += 0.1;  // Adjust the y-offset increment
    }

    // Set the camera and adjust view
    translate(width / 2, height / 2 + 100);
    rotateX(PI / 3);
    translate(-w / 2, -h / 2);

    // Draw the terrain
    for (int y = 0; y < rows - 1; y++) {
        beginShape(TRIANGLE_STRIP);  // Using TRIANGLE_STRIP to efficiently draw connected triangles
        for (int x = 0; x < cols; x++) {
            vertex(x * scale, y * scale, terrain[x][y]);  // First vertex
            vertex(x * scale, (y + 1) * scale, terrain[x][y + 1]);  // Vertex below
        }
        endShape();
    }

    // Reset transformations to draw 2D elements
    //resetMatrix();

    // Draw the arrow from the center of the screen to the mouse
    stroke(255, 0, 0);  // Red color for the arrow
    line(centerX, centerY, mouseX, mouseY);  // Draw the arrow

    // Draw the speed next to the arrow in the middle
    float midX = (centerX + mouseX) / 2;
    float midY = (centerY + mouseY) / 2;
    fill(255);  // White color for the text
    text("Speed: " + int(speed), midX + 10, midY);  // Display speed
}
