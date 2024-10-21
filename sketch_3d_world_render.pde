import java.util.ArrayList;

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
    private ArrayList<WorldObject> objects;

    public World() {
        this.objects = new ArrayList<>();
    }

    public void addObject(WorldObject obj) {
        this.objects.add(obj);
    }

    public void drawAll() {
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

    camera(0, -5000, 5000, 
        0, 0, 0,   
        0, 1, 0);   

    world = new World();
    world.addObject(new Cloud(new PVector(0, 0, 0), 500, 1000, 150, 1000));
    world.addObject(new Cloud(new PVector(0, -200, 0), 500, 500, 150, 500));
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
