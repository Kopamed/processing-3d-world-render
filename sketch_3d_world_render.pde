int cols, rows;
int scale = 10;  // Size of each grid square
int w = 1400;  // Width of the plane
int h = 1000;  // Height of the plane
float waterLevel = -30;  // The height at which water will appear (valleys)
float dirtDepth = -120;  // The depth of the dirt wall below the grass
float snowLevel = 70;  // The height above which snow appears
float rockLevel = 35;  // The height above which terrain becomes rocky (grey)
float snowThickness = 5;  // Thickness of the snow layer
float forwardShift;

float[][] terrain;  // Array to hold terrain height values

void setup() {
    fullScreen(P3D);
    noCursor();
    cols = w / scale;
    rows = h / scale;
    terrain = new float[cols][rows];
    forwardShift = -0;

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

    // **First pass: Draw the terrain with varying colors**
    stroke(50, 205, 50);  // Light green edges for the terrain

    for (int y = 0; y < rows - 1; y++) {
        beginShape(QUAD_STRIP);
        for (int x = 0; x < cols; x++) {
            // Determine the color of the terrain based on its height
            float height1 = terrain[x][y];
            float height2 = terrain[x][y + 1];

            // Apply colors based on terrain height:
            if (height1 > snowLevel) {
                // Snow at the highest peaks
                fill(255, 255, 255);  // White for snow
            } else if (height1 > rockLevel) {
                // Grey for rocky terrain between grass and snow
                fill(169, 169, 169);  // Grey color for rocks
            } else {
                // Green for grass at lower elevations
                fill(34, 139, 34);  // Green for grass
            }

            // Draw first vertex
            vertex(x * scale, y * scale, height1);

            if (height2 > snowLevel) {
                fill(255, 255, 255);  // Snow
            } else if (height2 > rockLevel) {
                fill(169, 169, 169);  // Grey rock
            } else {
                fill(34, 139, 34);  // Green grass
            }

            // Draw second vertex
            vertex(x * scale, (y + 1) * scale, height2);
        }
        endShape();
    }

    // **Second pass: Draw the dirt walls below the terrain**
    fill(66, 40, 14);  // Brown color for dirt walls
    noStroke();  // No edges for the dirt walls to make it smooth

    for (int y = 0; y < rows - 1; y++) {
        beginShape(QUADS);
        for (int x = 0; x < cols - 1; x++) {
            // Draw vertical dirt walls from the terrain down to the dirtDepth
            vertex(x * scale , y * scale - forwardShift, terrain[x][y]);  // Grass point
            vertex((x + 1) * scale, y * scale - forwardShift, terrain[x + 1][y]);  // Grass point

            vertex((x + 1) * scale, y * scale - forwardShift, dirtDepth);  // Dirt wall base
            vertex(x * scale, y * scale - forwardShift, dirtDepth);  // Dirt wall base
        }
        endShape();
    }

    // **Third pass: Draw the snow layer on top of high mountains**
    fill(255, 255, 255);  // White color for snow
    noStroke();  // No edges for snow to keep it smooth

    for (int y = 0; y < rows - 1; y++) {
        boolean drawingSnow = false;  // Track whether we are drawing a snow shape

        for (int x = 0; x < cols; x++) {
            // Check if terrain height is above the snow level
            if (terrain[x][y] > snowLevel || terrain[x][y + 1] > snowLevel) {
                if (!drawingSnow) {
                    beginShape(QUAD_STRIP);  // Start new snow strip
                    drawingSnow = true;
                }

                // Draw snow layer slightly above the terrain
                vertex(x * scale, y * scale, terrain[x][y] + snowThickness);
                vertex(x * scale, (y + 1) * scale, terrain[x][y + 1] + snowThickness);
            } else {
                // If the terrain drops below the snow level, end the shape to avoid connecting to the next snow region
                if (drawingSnow) {
                    endShape();
                    drawingSnow = false;
                }
            }
        }

        // Ensure the shape ends if we finished the row while still drawing snow
        if (drawingSnow) {
            endShape();
        }
    }

    // **Fourth pass: Draw the water**
    fill(0, 0, 255, 150);  // Semi-transparent blue for water
    noStroke();  // No edges for water to make it smooth

    for (int y = 0; y < rows - 1; y++) {
        beginShape(QUAD_STRIP);
        for (int x = 0; x < cols; x++) {
            if (terrain[x][y] < waterLevel || terrain[x][y + 1] < waterLevel) {
                // Draw water at water level
                vertex(x * scale, (y - 1) * scale, waterLevel);
                vertex(x * scale, (y) * scale, waterLevel);
            }
        }
        endShape();
    }
}
