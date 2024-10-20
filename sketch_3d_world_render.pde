int cols, rows;
int scale = 10;  // Size of each grid square
int w = 1400;  // Width of the plane
int h = 1000;  // Height of the plane
float waterLevel = -30;  // The height at which water will appear (valleys)

float[][] terrain;  // Array to hold terrain height values

void setup() {
    fullScreen(P3D);
    noCursor();
    cols = w / scale;
    rows = h / scale;
    terrain = new float[cols][rows];

    // Generate Perlin noise for each point in the grid once
    float yoff = 0;
    for (int y = 0; y < rows; y++) {
        float xoff = 0;
        for (int x = 0; x < cols; x++) {
            terrain[x][y] = map(noise(xoff, yoff), 0, 1, -100, 100);
            xoff += 0.1;
        }
        yoff += 0.1;
    }
}

void draw() {
    background(0);
    lights();  // Add lighting for depth
    directionalLight(255, 255, 255, 0, -1, -1);  // A white light shining from the top

    // Set the camera and adjust the view
    translate(width / 2, height / 2 + 100);
    rotateX(PI / 3);
    translate(-w / 2, -h / 2);

    // **First pass: Draw the terrain**
    fill(34, 139, 34);  // A green color to simulate grass
    stroke(50, 205, 50);  // Light green edges for the terrain

    for (int y = 0; y < rows - 1; y++) {
        beginShape(QUAD_STRIP);
        for (int x = 0; x < cols; x++) {
            vertex(x * scale, y * scale, terrain[x][y]);
            vertex(x * scale, (y + 1) * scale, terrain[x][y + 1]);
        }
        endShape();
    }

    // **Second pass: Draw the water**
    fill(0, 0, 255, 150);  // Semi-transparent blue for water
    noStroke();  // No edges for water to make it smooth

    for (int y = 0; y < rows - 1; y++) {
        beginShape(QUAD_STRIP);
        for (int x = 0; x < cols; x++) {
            if (terrain[x][y] < waterLevel || terrain[x][y + 1] < waterLevel) {
                // Draw water at water level
                vertex(x * scale, y * scale, waterLevel);
                vertex(x * scale, (y + 1) * scale, waterLevel);
            }
        }
        endShape();
    }
}
