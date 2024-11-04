// https://github.com/Kopamed/processing-3d-world-render
import java.util.ArrayList;
import java.util.HashSet;
import java.util.Set;
import java.util.List;
import java.util.Iterator;


// ===========  Misc functions ===========
void cylinder(float r, float h) {
    beginShape(QUAD_STRIP);
    for (int i = 0; i <= 360; i += 5) {
        float rad = radians(i);
        float x = cos(rad) * r;
        float y = sin(rad) * r;
        vertex(x, 0, y);
        vertex(x, h, y);
    }
    endShape();
}

void cone(float r, float h) {
    beginShape(TRIANGLE_FAN);
    // Tip of the cone at the origin
    vertex(0, -h, 0);
    for (int i = 0; i <= 360; i += 5) {
        float rad = radians(i);
        float x = cos(rad) * r;
        float z = sin(rad) * r;
        vertex(x, 0, z);
    }
    endShape();
}



// ===========  World config ===========
public interface ColorScheme {
    color getGrassColor();
    boolean shouldStroke();
    color getGrassStrokeColor();
    color getRockColor();
    color getWaterColor();
    color getTreeTrunkColor();
    color getTreeFoliageColor();
    color getCloudColor();
    color getRocketColor();
    color getRocketHeadColor();
    color getRocketFlameMinColor();
    color getRocketFlameMaxColor();
}


public class DefaultColorScheme implements ColorScheme {
    color[] autumnColors = {color(34, 139, 34), color(255, 255, 0), color(255, 165, 0), color(255, 69, 0), color(139, 69, 19)};

    @Override
    public color getGrassColor() {
        return color(34, 139, 34);
    }

    @Override
    public boolean shouldStroke() {
        return false;
    }

    @Override
    public color getGrassStrokeColor() {
        return color(50, 205, 50);
    }

    @Override
    public color getRockColor() {
        return color(169, 169, 169);
    }

    @Override
    public color getWaterColor() {
        return color(14, 67, 227, 164);
    }

    @Override
    public color getTreeTrunkColor() {
        return color(139, 69, 19);
    }

    @Override
    public color getTreeFoliageColor() {
        float t = random(1);
        int index1 = int(t * (autumnColors.length - 1)); 
        int index2 = index1 + 1;
        if (index2 >= autumnColors.length) index2 = index1; 
        return lerpColor(autumnColors[index1], autumnColors[index2], t % 1);
    }

    @Override
    public color getCloudColor() {
        return color(255, 255, 255);
    }

    @Override
    public color getRocketColor() {
        return color(255, 0, 0);
    }

    @Override
    public color getRocketHeadColor() {
        return color(128, 128, 128);
    }

    @Override
    public color getRocketFlameMinColor() {
        return color(255, 165, 0);
    }

    @Override
    public color getRocketFlameMaxColor() {
        return color(255, 0, 0);
    }
}


public interface WorldConfiguration {
    int getWorldHeight();

    float getWaterLevel();
    float getRockLevelStart();
    float getRockLevelFull();
}


public class DefaultWorldConfiguration implements WorldConfiguration {
    @Override
    public int getWorldHeight() {
        return 1250;
    }

    @Override
    public float getWaterLevel() {
        return 0.388 * getWorldHeight();
    }

    @Override
    public float getRockLevelStart() {
        return 0.6 * getWorldHeight();
    }

    @Override
    public float getRockLevelFull() {
        return 0.675 * getWorldHeight();
    }
}


// ===========  World Objects ===========
public abstract class WorldObject {
    protected PVector relativePosition;

    public WorldObject(PVector relativePosition) {
        this.relativePosition = relativePosition;
    }

    public PVector getRelativePosition() {
        return this.relativePosition;
    }

    public abstract void draw();
}


public class Cloud extends WorldObject {
    private static final float SPHERE_RADIUS_MIN = 20.0f;
    private static final float SPHERE_RADIUS_MAX = 75.0f;

    private PVector[] sphereOffsets;
    private float[] sphereRadiuses;
    private ColorScheme colorScheme;

    public Cloud(PVector position, int numSpheres, int width, int height, int length, ColorScheme colorScheme) {
        super(position);
        randomSeed((long)((int)position.x * 73856093 ^ (int)position.z * 19349663));

        if (numSpheres <= 0) {
            throw new IllegalArgumentException("Number of spheres must be greater than 0");
        }

        float halfWidth = width / 2;
        float halfHeight = height / 2;
        float halfLength = length / 2;

        if (halfWidth < SPHERE_RADIUS_MAX ||
            halfHeight < SPHERE_RADIUS_MAX ||
            halfLength < SPHERE_RADIUS_MAX) {
            throw new IllegalArgumentException("Sphere radius is too large for the cloud dimensions");
        }

        this.sphereOffsets = new PVector[numSpheres];
        this.sphereRadiuses = new float[numSpheres];
        this.colorScheme = colorScheme;

        float sphereRadius;
        for (int i = 0; i < numSpheres; i++) {
            sphereRadius = random(SPHERE_RADIUS_MIN, SPHERE_RADIUS_MAX);

            this.sphereOffsets[i] = new PVector(
                random(-halfWidth + sphereRadius, halfWidth - sphereRadius),
                random(-halfHeight + sphereRadius, halfHeight - sphereRadius),
                random(-halfLength + sphereRadius, halfLength - sphereRadius)
            );
            this.sphereRadiuses[i] = sphereRadius;
        }
    }

    @Override
    public void draw() {
        for (int i = 0; i < this.sphereOffsets.length; i++) {
            pushMatrix();
            translate(this.relativePosition.x + this.sphereOffsets[i].x, this.relativePosition.y + this.
            sphereOffsets[i].y, this.relativePosition.z + this.sphereOffsets[i].z);
            noStroke();
            fill(this.colorScheme.getCloudColor());
            sphere(this.sphereRadiuses[i]);
            popMatrix();
        }
    }
}


public class Tree extends WorldObject {
    private float trunkHeight;
    private float trunkRadius;
    private ColorScheme colorScheme;
    private color foliageColor;    
    private float foliageRadius;
    private float foliageHeight;

    public Tree(PVector relativePosition, float trunkHeight, float trunkRadius, float foliageRadius, float foliageHeight, ColorScheme colorScheme) {
        super(relativePosition);
        this.trunkHeight = trunkHeight;
        this.trunkRadius = trunkRadius;
        this.colorScheme = colorScheme;
        this.foliageRadius = foliageRadius;
        this.foliageHeight = foliageHeight;
        this.foliageColor = colorScheme.getTreeFoliageColor();
    }

    @Override
    public void draw() {
        pushMatrix();
        translate(this.relativePosition.x, this.relativePosition.y, this.relativePosition.z);

        fill(this.colorScheme.getTreeTrunkColor());
        noStroke();
        cylinder(this.trunkRadius, -this.trunkHeight);

        translate(0, -this.trunkHeight, 0);
        fill(this.foliageColor);
        cone(this.foliageRadius, this.foliageHeight);

        popMatrix();
    }
}


public class FlameParticle {
    PVector position;   // Position in rocket's local coordinates
    PVector velocity;   // Velocity in rocket's local coordinates
    int flameColor;
    float lifespan;     // In seconds

    public FlameParticle(PVector position, PVector velocity, int flameColor, float lifespan) {
        this.position = position.copy();
        this.velocity = velocity.copy();
        this.flameColor = flameColor;
        this.lifespan = lifespan;
    }

    public void update(float deltaTime) {
        // Update position based on velocity and time elapsed
        position.add(PVector.mult(velocity, deltaTime));
        // Decrease lifespan
        lifespan -= deltaTime;
    }

    public void draw() {
        pushMatrix();
        translate(position.x, position.y, position.z);
        float alpha = map(lifespan, 0, 0.5f, 0, 255);
        fill(red(flameColor), green(flameColor), blue(flameColor), alpha);
        noStroke();
        float size = map(lifespan, 0, 0.5f, 1, 15);
        sphere(size); // Use sphere for simplicity
        popMatrix();
    }

    public boolean isExpired() {
        return lifespan <= 0;
    }
}




public class Rocket extends WorldObject {
    // Existing properties
    private float rocketBodyHeight;
    private float rocketHeadHeight;
    private float rocketRadius;
    private ColorScheme colorScheme;
    private List<FlameParticle> flameParticles;

    public Rocket(PVector relativePosition, float rocketBodyHeight, float rocketHeadHeight, float rocketRadius, ColorScheme colorScheme) {
        super(relativePosition);
        this.rocketBodyHeight = rocketBodyHeight;
        this.rocketHeadHeight = rocketHeadHeight;
        this.rocketRadius = rocketRadius;
        this.colorScheme = colorScheme;
        this.flameParticles = new ArrayList<>();
    }

    // Update method to handle particle logic
    public void update(float deltaTime) {
        // Update existing particles
        Iterator<FlameParticle> iterator = flameParticles.iterator();
        while (iterator.hasNext()) {
            FlameParticle particle = iterator.next();
            particle.update(deltaTime);
            if (particle.isExpired()) {
                iterator.remove();
            }
        }

        // Calculate distance from mouse to center
        float centerX = width / 2;
        float centerY = height / 2;
        float distance = dist(centerX, centerY, mouseX, mouseY);
        float maxDistance = dist(0, 0, centerX, centerY); // Maximum possible distance

        // Map distance to speed range (50 to 500)
        float speed = map(distance, 0, maxDistance, 50, 500);

        // Spawn new particles with calculated speed
        spawnFlameParticles(speed);
    }


    private void spawnFlameParticles(float speed) {
        int particlesPerFrame = 5; // Adjust as needed
        for (int i = 0; i < particlesPerFrame; i++) {
            // Random color between min and max flame colors
            int flameColor = getRandomColor(
                colorScheme.getRocketFlameMinColor(),
                colorScheme.getRocketFlameMaxColor()
            );

            // Get the exhaust position in world coordinates
            PVector exhaustPositionWorld = getExhaustWorldPosition();

            // Get the velocity in world coordinates, applying the speed
            PVector velocityWorld = getRandomVelocityWorld(speed);

            // Lifespan in seconds
            float lifespan = 1f;

            // Create and add the flame particle
            FlameParticle particle = new FlameParticle(exhaustPositionWorld, velocityWorld, flameColor, lifespan);
            flameParticles.add(particle);
        }
    }

    private PVector getRandomVelocityWorld(float speed) {
        // Generate a random spread angle for lateral movement
        float spreadAngle = radians(15); // Adjust as needed

        // Random angles within the spread
        float angleX = random(-spreadAngle, spreadAngle);
        float angleY = random(-spreadAngle, spreadAngle);

        // Direction vector in local coordinates pointing away from the rocket's rear
        PVector localVelocity = new PVector(
            tan(angleX),  // Small lateral spread in X
            tan(angleY),  // Small lateral spread in Y
            1.0f          // Positive Z direction
        );

        localVelocity.normalize();
        localVelocity.mult(speed); // Use the calculated speed

        // Transform the velocity to world coordinates
        PVector worldVelocity = localToWorldDirection(localVelocity);

        return worldVelocity;
    }

    private PVector localToWorldDirection(PVector localDirection) {
        // Create a rotation matrix (exclude translations for direction vectors)
        PMatrix3D rotationMatrix = new PMatrix3D();
        rotationMatrix.rotateX(HALF_PI);

        // Use the same adjusted angle
        float centerX = width / 2;
        float centerY = height / 2;
        float dx = mouseX - centerX;
        float dy = mouseY - centerY;
        float angle = atan2(dy, dx);
        float adjustedAngle = angle + PI / 4;
        rotationMatrix.rotateZ(adjustedAngle);

        // Transform the local direction
        PVector worldDirection = localDirection.get();
        rotationMatrix.mult(worldDirection, worldDirection);

        return worldDirection;
    }



    private int getRandomColor(int minColor, int maxColor) {
        float t = random(0, 1);
        int r = (int) lerp(red(minColor), red(maxColor), t);
        int g = (int) lerp(green(minColor), green(maxColor), t);
        int b = (int) lerp(blue(minColor), blue(maxColor), t);
        return color(r, g, b);
    }

    private PVector getExhaustWorldPosition() {
    // The exhaust is at the rear of the rocket along the positive Z-axis in local coordinates
        PVector localExhaustPosition = new PVector(0, 0, -this.rocketBodyHeight * 5.2);

        // Apply the rocket's transformations to get the world position
        PVector worldExhaustPosition = localToWorldPosition(localExhaustPosition);

        return worldExhaustPosition;
    }

    private PVector localToWorldPosition(PVector localPosition) {
        // Create a new matrix to accumulate transformations
        PMatrix3D transformationMatrix = new PMatrix3D();

        // Apply transformations in the same order as in draw()
        transformationMatrix.translate(this.relativePosition.x, this.relativePosition.y, this.relativePosition.z);
        transformationMatrix.rotateX(HALF_PI);

        // Calculate the adjusted angle
        float centerX = width / 2;
        float centerY = height / 2;
        float dx = mouseX - centerX;
        float dy = mouseY - centerY;
        float angle = atan2(dy, dx);
        float adjustedAngle = angle + PI / 4;
        transformationMatrix.rotateZ(adjustedAngle);

        // Center the rocket body along the new Z-axis
        transformationMatrix.translate(0, 0, 0);

        // Transform the local position
        PVector worldPosition = localPosition.get();
        transformationMatrix.mult(worldPosition, worldPosition);

        return worldPosition;
    }


    private PMatrix3D getTransformationMatrix() {
        PMatrix3D matrix = new PMatrix3D();

        // Apply transformations in the same order as in draw()
        matrix.translate(this.relativePosition.x, this.relativePosition.y, this.relativePosition.z);
        matrix.rotateX(HALF_PI);

        // Calculate the adjusted angle
        float centerX = width / 2;
        float centerY = height / 2;
        float dx = mouseX - centerX;
        float dy = mouseY - centerY;
        float angle = atan2(dy, dx);
        float adjustedAngle = angle + PI / 4;
        matrix.rotateZ(adjustedAngle);

        // Center the rocket body along the new Z-axis
        matrix.translate(0, 0, -this.rocketBodyHeight / 2);

        return matrix;
    }


    private PVector getRandomVelocity() {
        // Generate a random direction pointing away from the rocket (along negative Z)
         float spreadAngle = radians(15); // Adjust as needed for wider or narrower flame

        // Random angle within the spread
        float angleXY = random(-spreadAngle, spreadAngle);

        // Random speed
        float speed = random(100, 200); // Adjust as needed

        // Direction vector pointing away from the rocket's rear along positive Z
        PVector dir = new PVector(
            sin(angleXY),            // Small lateral spread in X
            sin(angleXY),            // Small lateral spread in Y
            1.0f                     // Positive Z direction
        );

        dir.normalize();
        dir.mult(speed);

        return dir;
    }

    private PMatrix3D getRotationMatrix() {
        PMatrix3D matrix = new PMatrix3D();
        matrix.rotateX(HALF_PI);

        float centerX = width / 2;
        float centerY = height / 2;
        float dx = mouseX - centerX;
        float dy = mouseY - centerY;
        float angle = atan2(dy, dx);
        float adjustedAngle = angle + PI / 4;
        matrix.rotateZ(adjustedAngle);

        return matrix;
    }

    @Override
    public void draw() {
        // Draw the rocket
        pushMatrix();
        // Apply transformations
        translate(this.relativePosition.x, this.relativePosition.y, this.relativePosition.z);
        rotateX(HALF_PI);
        float centerX = width / 2;
        float centerY = height / 2;
        float dx = mouseX - centerX;
        float dy = mouseY - centerY;
        float angle = atan2(dy, dx);
        float adjustedAngle = angle - PI / 4;
        rotateZ(adjustedAngle);
        translate(0, 0, -this.rocketBodyHeight / 2);

        // Draw the rocket body and head
        fill(this.colorScheme.getRocketColor());
        noStroke();
        cylinder(this.rocketRadius, -this.rocketBodyHeight);
        fill(this.colorScheme.getRocketHeadColor());
        cone(this.rocketRadius, -this.rocketHeadHeight);
        for (FlameParticle particle : flameParticles) {
            particle.draw();
        }
        popMatrix();

        // Draw flame particles in world coordinates
        
    }


}


public class World {
    private WorldConfiguration worldConfiguration;
    private ColorScheme colorScheme;
    private ArrayList<WorldObject> objects;
    private float[][] terrain;
    private float resolution;
    private float scale;
    private float terrainSize;
    private int gridSize;
    private PVector position;
    private Set<PVector> generatedCloudCells;

    public World(PVector position, int gridSize, float resolution, float scale, WorldConfiguration worldConfiguration, ColorScheme colorScheme) {
        this.position = position;

        this.gridSize = gridSize;
        this.terrain = new float[gridSize][gridSize];
        this.resolution = resolution;
        this.scale = scale;
        this.colorScheme = colorScheme;
        this.worldConfiguration = worldConfiguration;
        this.terrainSize = gridSize * scale;
        this.objects = new ArrayList<>();

        this.generatedCloudCells = new HashSet<>();
    }

    public void setup() {
        this.objects.clear();
        generateWorld();
    }

    private void generateWorld() {
        pruneObjects();
        generateTerrain();
        //generateClouds();
    }

    private void generateTerrain() {
        float zoff = 0;
        for (int z = 0; z < gridSize; z++) { 
            float xoff = 0;
            for (int x = 0; x < gridSize; x++) {
                this.terrain[z][x] = map(noise(xoff + this.position.x, zoff + this.position.z), 0, 1, 0, this.worldConfiguration.getWorldHeight());  
                
                xoff += this.resolution;
            }
            zoff += this.resolution;
        }
    }

    private void pruneObjects() {
        float removalDistance = 2000; // Adjust as needed

        for (int i = 0; i < this.objects.size(); i++) {
            WorldObject obj = this.objects.get(i);
            PVector pos = obj.getRelativePosition();
            float distanceSquared = sq(pos.x - this.position.x) + sq(pos.z - this.position.z);

            if (distanceSquared > sq(removalDistance)) {
                this.objects.remove(i);
                i--;
            }
        }

        // Optionally, remove entries from generatedCloudCells that are too far
        float chunkRemovalDistance = 3; // Number of chunks
        int currentCellX = floor(this.position.x / 500);
        int currentCellZ = floor(this.position.z / 500);

        generatedCloudCells.removeIf(cell -> 
            abs(cell.x - currentCellX) > chunkRemovalDistance || 
            abs(cell.y - currentCellZ) > chunkRemovalDistance
        );
    }


    private void generateClouds() {
        // Define the size of each cloud chunk
        int cloudChunkSize = 500; // Adjust as needed
        float densityScale = 0.001f;
        float cloudThreshold = 0.65f;

        // Calculate the range around the current position to generate clouds
        int range = 2; // Number of chunks around the current position

        // Calculate the grid cell coordinates for the current position
        int currentCellX = floor(this.position.x / cloudChunkSize);
        int currentCellZ = floor(this.position.z / cloudChunkSize);

        for (int dz = -range; dz <= range; dz++) {
            for (int dx = -range; dx <= range; dx++) {
                int cellX = currentCellX + dx;
                int cellZ = currentCellZ + dz;

                // Create a unique identifier for the grid cell
                PVector cell = new PVector(cellX, cellZ);

                if (!generatedCloudCells.contains(cell)) {
                    // Mark this cell as generated
                    generatedCloudCells.add(cell);

                    // Generate clouds for this cell based on noise
                    float noiseValue = noise(cellX * densityScale, cellZ * densityScale);

                    if (noiseValue > cloudThreshold) {
                        float cloudX = cellX * cloudChunkSize + cloudChunkSize / 2;
                        float cloudZ = cellZ * cloudChunkSize + cloudChunkSize / 2;

                        // Adjust positions to center the cloud in the chunk
                        this.addObject(new Cloud(
                            new PVector(cloudX, random(-1500, -1200), cloudZ),
                            20, 300, 150, 300,
                            this.getColorScheme()
                        ));
                    }
                }
            }
        }
    }

    public void move(PVector positionChange) {
        this.position.add(positionChange); // Use add() to update the position

        if (positionChange.x != 0 || positionChange.z != 0) { // Fix the typo here
            generateWorld();
        }
    }


    public void addObject(WorldObject obj) {
        this.objects.add(obj);
    }

    public float getHeightFromArray(int x, int z) {
        if (x < 0 || x >= this.gridSize || z < 0 || z >= this.gridSize) {
            throw new IllegalArgumentException("Invalid coordinates");
        }

        return this.terrain[z][x];
    }

    public WorldConfiguration getWorldConfiguration() {
        return this.worldConfiguration;
    }

    public ColorScheme getColorScheme() {
        return this.colorScheme;
    }

    public float getScale() {
        return this.scale;
    }

    public float getTerrainSize() {
        return this.terrainSize;
    }

    public void drawAll() {
        pushMatrix();
        translate(-this.terrainSize / 2, 0, -this.terrainSize / 2);

        if(this.colorScheme.shouldStroke()) {
            stroke(this.colorScheme.getGrassStrokeColor());
        } else {
            noStroke();
        }

        for (int z = 0; z < this.terrain.length - 1; z++) {
            beginShape(QUAD_STRIP);
            for (int x = 0; x < this.terrain[z].length; x++) {
                float height1 = this.terrain[z][x];
                float height2 = this.terrain[z + 1][x];

                float t;

                t = map(height1, this.worldConfiguration.getRockLevelStart(), this.worldConfiguration.getRockLevelFull(), 0, 1);
                fill(lerpColor(this.colorScheme.getGrassColor(), this.colorScheme.getRockColor(), t));
                vertex(x * scale, -height1, z * scale);

                t = map(height2, this.worldConfiguration.getRockLevelStart(), this.worldConfiguration.getRockLevelFull(), 0, 1);
                fill(lerpColor(this.colorScheme.getGrassColor(), this.colorScheme.getRockColor(), t));
                vertex(x * scale, -height2, (z + 1) * scale);
            }
            endShape();
        }

        fill(this.colorScheme.getWaterColor());
        noStroke();

        beginShape(QUADS);  
        vertex(0, -this.worldConfiguration.getWaterLevel(), 0);               // Bottom-left corner
        vertex(this.terrainSize, -this.worldConfiguration.getWaterLevel(), 0);    // Bottom-right corner
        vertex(this.terrainSize, -this.worldConfiguration.getWaterLevel(), this.terrainSize);  // Top-right corner
        vertex(0, -this.worldConfiguration.getWaterLevel(), this.terrainSize);    // Top-left corner
        endShape();

        popMatrix();

        for (WorldObject obj : this.objects) {
            obj.draw(); 
        }
    }
}


// ===========  Helper functions ===========
void populateWithTrees(World world) {
    float treeThreshold = 0.5;
    float densityScale = 0.008;
    WorldConfiguration worldConfiguration = world.getWorldConfiguration();
    float scale = world.getScale();
    float terrainSize = world.getTerrainSize(); 

    for (int z = 0; z < world.terrain.length; z++) {
        for (int x = 0; x < world.terrain[z].length; x++) {
            float noiseValue = noise(x * densityScale, z * densityScale);
 
            if (noiseValue > treeThreshold) {
                float height = world.terrain[z][x];  
                if (height > worldConfiguration.getRockLevelStart() || height < worldConfiguration.getWaterLevel()) {
                    continue;
                }

                // I suck at graphics ffs
                float adjustedX = x * scale - terrainSize / 2;
                float adjustedZ = z * scale - terrainSize / 2;

                world.addObject(new Tree(
                    new PVector(adjustedX, -height, adjustedZ),  
                    6,
                    2,
                    4,  
                    10,  
                    world.getColorScheme()
                ));
            }
        }
    }
}

// ===========  Misc functions ===========
void drawFPS() {
    // Switch to 2D overlay mode
    hint(DISABLE_DEPTH_TEST); // Disable depth test for overlay text
    camera(); // Reset the camera to default for 2D drawing
    ortho(); // Switch to orthographic projection for 2D

    // Draw FPS counter
    fill(255); // Set text color to white
    textSize(16);
    text("FPS: " + int(frameRate), 10, 20); // Display FPS at the top-left corner

    // Restore 3D settings
    hint(ENABLE_DEPTH_TEST); // Re-enable depth test for 3D rendering
    perspective(); // Restore perspective projection
    apply3DCamera(); // Reapply custom 3D camera settings
}

void apply3DCamera() {
    float d = 2600;
    camera(-d, -d, d, 
           0, 0, 0,   
           0, 1, 0);
}

void moveWorldFromMouse(World world, float sensitivity) {
    // Calculate distance and angle from the mouse to the center of the screen
    float centerX = width / 2;
    float centerY = height / 2;
    float dx = mouseX - centerX;
    float dy = mouseY - centerY;

    // Calculate distance and normalize to control speed
    float distance = dist(centerX, centerY, mouseX, mouseY);
    float maxDistance = dist(0, 0, centerX, centerY); // Maximum possible distance
    float speed = map(distance, 0, maxDistance, 0, sensitivity); // Use sensitivity as the maximum speed

    // Calculate direction
    float angle = atan2(dy, dx);

    // Adjust for the 45-degree rotation by rotating the angle by -45 degrees
    float adjustedAngle = angle + PI / 4;
    float moveX = cos(adjustedAngle) * speed;
    float moveZ = sin(adjustedAngle) * speed;

    // Move the world based on the adjusted direction and speed
    world.move(new PVector(moveX, 0, moveZ));
}


// ===========  Pre-setup ===========
World world;
Rocket rocket;
float lastFrameTime = 0;

/*
    The following 3 variables determine what the world looks like
    These values work well together. These values were found from a lot of trial and error
    There is no reasoning behind them. I just found them to look good
*/
final float REALISTIC_RESOLUTION = 0.0035f;
final float REALISTIC_SCALE = 1.5f;
final int PLEASANT_WORLD_VISUAL_SIZE = 2500;

/* 
    The following variable will scale the size of each rendered quad of the plane in your world.
    Bigger quads = better performance = more FPS = worse quality
    If the world looks too ugly, try decreasing this value
    If your FPS is too low, try increasing this value
    Long story short, just like with everything in life, find a balance. Or a better programmer.
*/
final int HOW_BAD_IS_YOUR_COMPUTER = 10;

// One time calculation
final int GRID_SIZE = PLEASANT_WORLD_VISUAL_SIZE / HOW_BAD_IS_YOUR_COMPUTER;
final float RESOLUTION = REALISTIC_RESOLUTION * HOW_BAD_IS_YOUR_COMPUTER;
final float SCALE = REALISTIC_SCALE * HOW_BAD_IS_YOUR_COMPUTER;

// Movement constants
final float MOVEMENT_SENSITIVITY = 0.15f;


// ===========  Processing Functions ===========
void setup() {
    fullScreen(P3D);
    //noiseSeed(42);

    apply3DCamera();

    ColorScheme defaultColorScheme = new DefaultColorScheme();

    world = new World(new PVector(0, 0, 0), GRID_SIZE, RESOLUTION, SCALE, new DefaultWorldConfiguration(), defaultColorScheme);
    world.setup();

    rocket = new Rocket(new PVector(0, -world.getWorldConfiguration().getWorldHeight(), 0), 200, 50, 25, defaultColorScheme);
    world.addObject(rocket);
}


void draw() {
    float currentTime = millis() / 1000.0; // Convert to seconds
    float deltaTime = currentTime - lastFrameTime;
    lastFrameTime = currentTime;

    background(0, 0, 0);

    lights();
    directionalLight(255, 255, 255, 0, -1, -1);

    moveWorldFromMouse(world, MOVEMENT_SENSITIVITY);
    rocket.update(deltaTime);
    rocket.draw();
    world.drawAll();

    if (frameCount == 1) {
        save("output/output.tif");
    }

    drawFPS();
}

