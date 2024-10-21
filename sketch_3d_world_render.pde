import java.util.ArrayList;

/*
// General configuration
int cols, rows;
int scale = 20;
int planeSize = 10000;

// World configuration
float waterLevel = 32;
float dirtDepth = -20;
float rockLevel = 80;

// Misc configuration
int nTrees = 200;
int nClouds = 10;
*/

// ===========  World config ===========
public interface ColorScheme {
    color getGrassColor();
    boolean shouldStroke();
    color getGrassStrokeColor();
    color getRockColor();
    color getWaterColor();
}


public class DefaultColorScheme implements ColorScheme {
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
        return color(0, 0, 255);
    }
}


public interface WorldConfiguration {
    float getWaterLevel();
    float getRockLevel();
}


public class DefaultWorldConfiguration implements WorldConfiguration {
    @Override
    public float getWaterLevel() {
        return 320;
    }

    @Override
    public float getRockLevel() {
        return 600;
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

    public Cloud(PVector position, int numSpheres, int width, int height, int length) {
        super(position);

        if (numSpheres <= 0) {
            throw new IllegalArgumentException("Number of spheres must be greater than 0");
        }

        float halfWidth = width / 2;
        float halfHeight = height / 2;
        float halfLength = length / 2;

        println("Half width: " + halfWidth, "Half height: " + halfHeight, "Half length: " + halfLength, "Sphere radius min: " + SPHERE_RADIUS_MIN, "Sphere radius max: " + SPHERE_RADIUS_MAX);

        if (halfWidth < SPHERE_RADIUS_MAX ||
            halfHeight < SPHERE_RADIUS_MAX ||
            halfLength < SPHERE_RADIUS_MAX) {
            throw new IllegalArgumentException("Sphere radius is too large for the cloud dimensions");
        }

        this.sphereOffsets = new PVector[numSpheres];
        this.sphereRadiuses = new float[numSpheres];

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
            sphere(this.sphereRadiuses[i]);
            popMatrix();
        }
    }
}


public class World {
    private WorldConfiguration worldConfiguration;
    private ColorScheme colorScheme;
    private ArrayList<WorldObject> objects;
    private float[][] terrain;
    private float scale;
    private float terrainSize;

    public World(int gridSize, float resolution, float scale, WorldConfiguration worldConfiguration, ColorScheme colorScheme) {
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

                if (height1 > this.worldConfiguration.getRockLevel()) {
                    fill(this.colorScheme.getRockColor());
                } else {
                    fill(this.colorScheme.getGrassColor()); 
                }
                vertex(x * scale, -height1, z * scale);

                if (height2 > this.worldConfiguration.getRockLevel()) {
                    fill(this.colorScheme.getRockColor());
                } else {
                    fill(this.colorScheme.getGrassColor()); 
                }
                vertex(x * scale, -height2, (z + 1) * scale);
            }
            endShape();
        }

        popMatrix();

        for (WorldObject obj : this.objects) {
            obj.draw(); 
        }
    }
}


// ===========  Pre-setup ===========
World world;


// ===========  Processing Functions ===========
void setup() {
    fullScreen(P3D);

    camera(0, -1900, 1800, 
        0, 0, 0,   
        0, 1, 0);   

    world = new World(250, 0.05f, 15, new DefaultWorldConfiguration(), new DefaultColorScheme());
    world.addObject(new Cloud(new PVector(0, -2000, 0), 500, 500, 150, 500));
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
