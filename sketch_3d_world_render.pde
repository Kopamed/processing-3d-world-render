int cols, rows;
int scale = 10;  // Size of each grid square
int w = 1400;  // Width of the plane
int h = 1000;  // Height of the plane
float waterLevel = -30;  // The height at which water will appear (valleys)
float dirtDepth = -120;  // The depth of the dirt wall below the grass
float rockLevel = 30;  // The height above which terrain becomes rocky (grey)
float forwardShift;
int numTrees = 100;  // Number of trees to randomly place on the terrain

// Array to hold tree positions
PVector[] treePositions;

float[][] terrain;  // Array to hold terrain height values

void setup() {
    fullScreen(P3D);
    noCursor();
    cols = w / scale;
    rows = h / scale;
    terrain = new float[cols][rows];
    treePositions = new PVector[numTrees];  // Array to hold tree positions
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

    // Generate tree positions only once in setup
    for (int i = 0; i < numTrees; i++) {
        int tx, ty;
        float height;

        // Keep generating random positions until a valid grassy position is found
        do {
            tx = int(random(cols));  // Random x-coordinate for tree
            ty = int(random(rows));  // Random y-coordinate for tree
            height = terrain[tx][ty];
        } while (height <= waterLevel || height >= rockLevel);

        // Save the tree's position in the array
        treePositions[i] = new PVector(tx * scale, ty * scale, height);
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
            if (height1 > rockLevel) {
                // Grey for rocky terrain above the rock level
                fill(169, 169, 169);  // Grey color for rocks
            } else {
                // Green for grass at lower elevations
                fill(34, 139, 34);  // Green for grass
            }

            // Draw first vertex
            vertex(x * scale, y * scale, height1);

            if (height2 > rockLevel) {
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

    // **Third pass: Draw the water**
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

    // **Fourth pass: Draw trees using precomputed positions**
    for (int i = 0; i < numTrees; i++) {
        PVector treePos = treePositions[i];
        drawTree(treePos.x, treePos.y, treePos.z);
    }
}

// Function to draw a simple tree (cylinder trunk, cone foliage)
void drawTree(float x, float y, float z) {
    pushMatrix();
    translate(x, y, z);  // Position the tree on the terrain

    // Draw the trunk
    fill(139, 69, 19);  // Brown color for the trunk
    cylinder(2, 20);  // Trunk radius and height

    // Draw the foliage (a green cone)
    translate(0, 0, 20);  // Move to the top of the trunk
    fill(34, 139, 34);  // Green color for foliage
    cone(10, 25);  // Foliage radius and height

    popMatrix();
}

// Function to draw a cylinder (for the tree trunk)
void cylinder(float r, float h) {
    beginShape(QUAD_STRIP);
    for (int i = 0; i <= 360; i += 5) {
        float rad = radians(i);
        float x = cos(rad) * r;
        float y = sin(rad) * r;
        vertex(x, y, 0);
        vertex(x, y, h);
    }
    endShape();
}

// Function to draw a cone (for the tree foliage)
void cone(float r, float h) {
    // Draw the base of the cone
    beginShape(TRIANGLE_FAN);
    vertex(0, 0, h);  // Cone tip
    for (int i = 0; i <= 360; i += 5) {
        float rad = radians(i);
        float x = cos(rad) * r;
        float y = sin(rad) * r;
        vertex(x, y, 0);
    }
    endShape();
}
