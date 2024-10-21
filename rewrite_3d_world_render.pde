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
public abstract WorldObject {
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
    private static final float SPHERE_RADIUS_MIN = 5.0f;
    private static final float SPHERE_RADIUS_MAX = 25.0f;

    private PVector sphereOffsets[];
    private float sphereSizes[];

    public Cloud(PVector position, int numSpheres, int width, int height, int length) {
        super(position);

        this.sphereOffsets = new PVector[numSpheres];
        this.sphereSizes = new float[numSpheres];
        
        float halfWidth = width / 2;
        float halfHeight = height / 2;
        float halfLength = length / 2;

        float sphereSize;
        for (int i = 0; i < numSpheres; i++) {
            sphereSize = random(10, 50);

            this.sphereOffsets[i] = new PVector(
                random(-halfWidth, halfWidth),
                random(-halfHeight, halfHeight),
                random(-halfLength, halfLength)
            );
        }
    }
}