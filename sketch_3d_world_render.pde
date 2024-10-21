int cols, rows;
int scale = 20;  // Size of each grid square
int w = 2800;  // Width of the plane (doubled)
int h = 2000;  // Height of the plane (doubled)
float waterLevel = -30;  // The height at which water will appear (valleys)
float dirtDepth = -120;  // The depth of the dirt wall below the grass
float rockLevel = 60;  // The height above which terrain becomes rocky (grey), raised for bigger mountains
float forwardShift;
int numTrees = 200;  // Number of trees to randomly place on the terrain (increased tree count)
int numClouds = 10;  // Number of clouds to generate

// Arrays to hold tree and cloud positions/colors
PVector[] treePositions;
color[] treeColors;
Cloud[] clouds;  // Array of Cloud objects (each cloud is a collection of spheres)

float[][] terrain;  // Array to hold terrain height values

// Autumn colors for the tree foliage spectrum
color[] autumnColors = {color(34, 139, 34), color(255, 255, 0), color(255, 165, 0), color(255, 69, 0), color(139, 69, 19)};  // Green to brown

void setup() {
    fullScreen(P3D);
    noCursor();
    cols = w / scale;
    rows = h / scale;
    terrain = new float[cols][rows];
    treePositions = new PVector[numTrees];  // Array to hold tree positions
    treeColors = new color[numTrees];  // Array to hold tree colors
    clouds = new Cloud[numClouds];  // Array to hold clouds
    forwardShift = -0;

    // Generate Perlin noise for each point in the grid once (with a larger height range for bigger mountains)
    float yoff = 0;
    for (int y = 0; y < rows; y++) {
        float xoff = 0;
        for (int x = 0; x < cols; x++) {
            terrain[x][y] = map(noise(xoff, yoff), 0, 1, -200, 200);  // Larger height range for higher mountains
            xoff += 0.1;
        }
        yoff += 0.1;
    }

    // Generate tree positions and preset their colors only once in setup
    for (int i = 0; i < numTrees; i++) {
        int tx, ty;
        float height;

        // Keep generating random positions until a valid grassy position is found
        do {
            tx = int(random(cols));  // Random x-coordinate for tree
            ty = int(random(rows));  // Random y-coordinate for tree
            height = terrain[tx][ty];
        } while (height <= waterLevel || height >= rockLevel);

        // Save the tree's position and assign a preset autumn color
        treePositions[i] = new PVector(tx * scale, ty * scale, height);
        treeColors[i] = getAutumnColor();  // Assign a random autumn color
    }

    // Precompute cloud details (position, number of spheres, sphere offsets, and sizes)
    for (int i = 0; i < numClouds; i++) {
        float cx = random(width);  // Random x position within world
        float cy = random(height);  // Random y position within world
        float cz = random(150, 300);  // Random cloud altitude
        clouds[i] = new Cloud(new PVector(cx, cy, cz), 20);  // 5 spheres per cloud
    }
}

void draw() {
    background(0, 0, 0);  // Sky blue background
    lights();  // Add lighting for depth
    directionalLight(255, 255, 255, 0, -1, -1);  // A white light shining from the top

    // Set the camera and adjust the view
    translate(width / 2, height / 2);
    rotateX(PI / 4);
    translate(-w / 2, -h / 2 - 400);

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

    // **Fourth pass: Draw trees using precomputed positions and colors**
    for (int i = 0; i < numTrees; i++) {
        PVector treePos = treePositions[i];
        drawTree(treePos.x, treePos.y, treePos.z, treeColors[i]);  // Use preset color for each tree
    }

    // **Fifth pass: Draw precomputed clouds**
    for (int i = 0; i < numClouds; i++) {
        clouds[i].drawCloud();
    }
}

// Function to draw a simple tree (cylinder trunk, cone foliage)
void drawTree(float x, float y, float z, color foliageColor) {
    pushMatrix();
    translate(x, y, z);  // Position the tree on the terrain

    // Draw the trunk
    fill(139, 69, 19);  // Brown color for the trunk
    cylinder(2, 20);  // Trunk radius and height

    // Draw the foliage with preset autumn color
    translate(0, 0, 20);  // Move to the top of the trunk
    fill(foliageColor);  // Use preset autumn foliage color
    cone(10, 25);  // Foliage radius and height

    popMatrix();
}

// Function to get a random autumn color by interpolating between colors
color getAutumnColor() {
    float t = random(1);  // Random interpolation factor between 0 and 1
    int index1 = int(t * (autumnColors.length - 1));  // Get the first color index
    int index2 = index1 + 1;  // Get the next color index
    if (index2 >= autumnColors.length) index2 = index1;  // Handle edge case

    // Interpolate between the two colors
    return lerpColor(autumnColors[index1], autumnColors[index2], t % 1);
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

// Class to represent a Cloud made of multiple precomputed spheres
class Cloud {
    PVector position;
    PVector[] sphereOffsets;  // Offsets for each sphere in the cloud
    float[] sphereSizes;      // Sizes of each sphere

    // Constructor to initialize cloud with random sphere positions and sizes
    Cloud(PVector pos, int numSpheres) {
        position = pos;
        sphereOffsets = new PVector[numSpheres];
        sphereSizes = new float[numSpheres];
        for (int i = 0; i < numSpheres; i++) {
            // Random offsets for each sphere within the cloud
            float offsetX = random(-30, 30);
            float offsetY = random(-15, 15);
            float offsetZ = random(-10, 10);
            sphereOffsets[i] = new PVector(offsetX, offsetY, offsetZ);

            // Random size for each sphere
            sphereSizes[i] = random(30, 60);
        }
    }

    // Method to draw the cloud
    void drawCloud() {
        pushMatrix();
        translate(position.x, position.y, position.z);  // Position the cloud

        // Draw all the spheres in the cloud
        for (int i = 0; i < sphereOffsets.length; i++) {
            PVector offset = sphereOffsets[i];
            translate(offset.x, offset.y, offset.z);
            fill(255, 255, 255);  // White color for clouds
            noStroke();  // No stroke for clouds
            sphere(sphereSizes[i]);  // Draw sphere with precomputed size
            translate(-offset.x, -offset.y, -offset.z);  // Reset translation
        }

        popMatrix();
    }
}
