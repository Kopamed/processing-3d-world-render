import java.util.ArrayList;


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
    vertex(0, -h, 0);
    for (int i = 0; i <= 360; i += 5) {
        float rad = radians(i);
        float x = cos(rad) * r;
        float y = sin(rad) * r;
        vertex(x, 0, y);
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
        return color(0, 0, 255, 196);
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

    if (frameCount == 1) {
        save("output/output.tif");
        exit();  // Automatically close after saving the file
    }
}


public interface WorldConfiguration {
    float getWaterLevel();
    float getRockLevelStart();
    float getRockLevelFull();
}


public class DefaultWorldConfiguration implements WorldConfiguration {
    @Override
    public float getWaterLevel() {
        return 388;
    }

    @Override
    public float getRockLevelStart() {
        return 600;
    }

    @Override
    public float getRockLevelFull() {
        return 675;
    }
}


// ===========  World Objects ===========
public abstract class WorldObject {
    protected PVector position;

    public WorldObject(PVector position) {
        this.position = position;
    }

    public PVector getPosition() {
        return this.position;
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
            translate(this.position.x + this.sphereOffsets[i].x, this.position.y + this.
            sphereOffsets[i].y, this.position.z + this.sphereOffsets[i].z);
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

    public Tree(PVector position, float trunkHeight, float trunkRadius, float foliageRadius, float foliageHeight, ColorScheme colorScheme) {
        super(position);
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
        translate(this.position.x, this.position.y, this.position.z);

        fill(this.colorScheme.getTreeTrunkColor());
        noStroke();
        cylinder(this.trunkRadius, -this.trunkHeight);

        translate(0, -this.trunkHeight, 0);
        fill(this.foliageColor);
        cone(this.foliageRadius, this.foliageHeight);

        popMatrix();
    }
}


public class World {
    private WorldConfiguration worldConfiguration;
    private ColorScheme colorScheme;
    private ArrayList<WorldObject> objects;
    private float[][] terrain;
    private float scale;
    private float terrainSize;
    private int gridSize;

    public World(int gridSize, float resolution, float scale, WorldConfiguration worldConfiguration, ColorScheme colorScheme) {
        this.gridSize = gridSize;
        this.terrain = new float[gridSize][gridSize];
        this.scale = scale;
        this.colorScheme = colorScheme;
        this.worldConfiguration = worldConfiguration;
        this.terrainSize = gridSize * scale;

        float zoff = 0;
        for (int z = 0; z < gridSize; z++) { 
            float xoff = 0;
            for (int x = 0; x < gridSize; x++) {
                this.terrain[z][x] = map(noise(xoff, zoff), 0, 1, 0, 1000);  
                
                xoff += resolution;
            }
            zoff += resolution;
        }


        this.objects = new ArrayList<>();
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
    float acceptanceChance = 0.04;
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

                if (random(1) < 1 - acceptanceChance) {
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

void populateWithClouds(World world) {
    float cloudThreshold = 0.65;  
    float densityScale = 0.001;
    float acceptanceChance = 0.5;
    WorldConfiguration worldConfiguration = world.getWorldConfiguration();
    float scale = world.getScale();
    float terrainSize = world.getTerrainSize(); 

    for (int z = 0; z < world.terrain.length; z += 100) {  
        for (int x = 0; x < world.terrain[z].length; x += 100) {
            float noiseValue = noise(x * densityScale, z * densityScale);
            
            if (noiseValue > cloudThreshold) {  

                if (random(1) < 1 - acceptanceChance) {
                    continue;
                }

                float adjustedX = x * scale - terrainSize / 2;
                float adjustedZ = z * scale - terrainSize / 2;

                world.addObject(new Cloud(
                    new PVector(adjustedX, random(-1500, -1200), adjustedZ),  
                    20,  // Number of spheres in the cloud
                    300, // Cloud width
                    150, // Cloud height
                    300, // Cloud length
                    world.getColorScheme()
                ));
            }
        }
    }
}


// ===========  Pre-setup ===========
World world;


// ===========  Processing Functions ===========
void setup() {
    size(1920, 1080, P3D);
    noiseSeed(42);

    float d = 2600;
    camera(-d, -d, d, 
        0, 0, 0,   
        0, 1, 0);

    ColorScheme defaultColorScheme = new DefaultColorScheme();

    world = new World(2500, 0.0035f, 1.5f, new DefaultWorldConfiguration(), defaultColorScheme);
    populateWithTrees(world);
    populateWithClouds(world);
}


void draw() {
    background(0, 0, 0);

    lights();
    directionalLight(255, 255, 255, 0, -1, -1);

    world.drawAll();

    if (frameCount == 1) {
        save("output/output.tif");
    }
}
