int cols, rows;
int scale = 10;  // Size of each grid square
int w = 1400;  // Width of the plane
int h = 1000;  // Height of the plane

float[][] terrain;  // Array to hold terrain height values
float flying = 0;  // Variable to animate the noise

void setup() {
    size(1280, 720, P3D);
    cols = w / scale;
    rows = h / scale;
    terrain = new float[cols][rows];
}

void draw() {
    background(0);
    stroke(255);
    noFill();

    // Update the "flying" variable to animate the terrain
    flying -= 0.05;

    // Generate Perlin noise for each point in the grid
    float yoff = flying;  // Varying offset in the y-direction for noise
    for (int y = 0; y < rows; y++) {
        float xoff = 0;  // Reset the x offset at the beginning of each row
        for (int x = 0; x < cols; x++) {
            // Use noise() function to determine the height at each point
            terrain[x][y] = map(noise(xoff, yoff), 0, 1, -100, 100);
            xoff += 0.1;  // Adjust the x-offset increment
        }
        yoff += 0.1;  // Adjust the y-offset increment
    }

    // Set the camera
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
}
