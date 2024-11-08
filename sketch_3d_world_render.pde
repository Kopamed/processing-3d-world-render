// https://github.com/Kopamed/processing-3d-world-render
import processing.core.PImage;
import processing.core.PVector;
import java.util.HashMap;
import java.util.Map;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Iterator;
import java.util.Map.Entry;


public enum BlockFace {
    TOP(0),
    SIDE(1),
    BOTTOM(2);

    private final int faceID;

    BlockFace(int faceID) {
        this.faceID = faceID;
    }

    public int getFaceID() {
        return faceID;
    }
}


public enum BlockType {
    GRASS(0);

    private final int blockID;

    BlockType(int blockID) {
        this.blockID = blockID;
    }

    public int getBlockID() {
        return blockID;
    }
}



// ==========  Caching  ==========
class CacheKey<T, U> {
    private final T blockType;
    private final U face;

    public CacheKey(T blockType, U face) {
        this.blockType = blockType;
        this.face = face;
    }

    public T getBlockType() {
        return blockType;
    }

    public U getFace() {
        return face;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        
        CacheKey<?, ?> cacheKey = (CacheKey<?, ?>) o;
        return Objects.equals(blockType, cacheKey.blockType) && Objects.equals(face, cacheKey.face);
    }

    @Override
    public int hashCode() {
        return Objects.hash(blockType, face);
    }
}


class CacheValue {
    private final PImage sprite;
    private long lastAccessTime;

    public CacheValue(PImage sprite) {
        this.sprite = sprite;
        this.lastAccessTime = System.currentTimeMillis();
    }

    public PImage getSprite() {
        this.lastAccessTime = System.currentTimeMillis();
        return sprite;
    }

    public long getLastAccessTime() {
        return lastAccessTime;
    }
}


// ==========  General Sprite Sheet  ==========
public interface SpriteSheet<T, U> {
    PImage getSprite(T blockType, U face);
    int spriteSize();
    int spritesPerBlock();
    void clearOldCacheEntries(long maxAge);
    void clearCache();
}


public class EightBitMinecraftSpriteSheet implements SpriteSheet<BlockType, BlockFace> {
    private final PImage spriteSheet;
    private final int spriteSize;
    private final int spriteSheetWidth;
    private final int spriteSheetHeight;
    private final int spritesPerBlock;
    private final int spritesPerRow;
    private final Map<CacheKey<BlockType, BlockFace>, CacheValue> spriteCache = new HashMap<>();

    public EightBitMinecraftSpriteSheet(String path, int spriteSheetWidth, int spriteSheetHeight) {
        this.spriteSize = 8;
        this.spritesPerBlock = 3;

        if (spriteSheetWidth % spriteSize != 0 || spriteSheetHeight % spriteSize != 0) {
            throw new IllegalArgumentException("Sprite sheet dimensions must be multiples of sprite size");
        }

        this.spriteSheet = loadSpriteSheet(path);
        this.spriteSheetWidth = spriteSheetWidth;
        this.spriteSheetHeight = spriteSheetHeight;
        this.spritesPerRow = spriteSheetWidth / spriteSize;
    }

    @Override
    public PImage getSprite(BlockType blockType, BlockFace face) {
        CacheKey<BlockType, BlockFace> key = new CacheKey<>(blockType, face);

        if (spriteCache.containsKey(key)) {
            return spriteCache.get(key).getSprite();
        }

        int spriteIndex = blockType.getBlockID() * spritesPerBlock + face.getFaceID();
        int x = (spriteIndex % spritesPerRow) * spriteSize;
        int y = (spriteIndex / spritesPerRow) * spriteSize;

        PImage sprite = spriteSheet.get(x, y, spriteSize, spriteSize);
        spriteCache.put(key, new CacheValue(sprite));
        return sprite;
    }


    private PImage loadSpriteSheet(String path) {
        return loadImage(path); // This assumes you have a loadImage method available
    }

    @Override
    public int spriteSize() {
        return spriteSize;
    }

    @Override
    public int spritesPerBlock() {
        return spritesPerBlock;
    }

    @Override
    public void clearOldCacheEntries(long maxAge) {
        long currentTime = System.currentTimeMillis();
        Iterator<Map.Entry<CacheKey<BlockType, BlockFace>, CacheValue>> iterator = spriteCache.entrySet().iterator();

        while (iterator.hasNext()) {
            Map.Entry<CacheKey<BlockType, BlockFace>, CacheValue> entry = iterator.next();
            long lastAccessTime = entry.getValue().getLastAccessTime();

            if (currentTime - lastAccessTime > maxAge) {
                iterator.remove();
            }
        }
    }

    @Override
    public void clearCache() {
        spriteCache.clear();
    }
}


// ========== Objects ==========
public class Block {
    private final World world;
    private final PVector position;
    private final int size;
    private final BlockType blockType;

    public Block(World world, PVector position, BlockType blockType, int size) {
        this.world = world;
        this.position = position;
        this.blockType = blockType;
        this.size = size;
    }

    public void draw() {
        pushMatrix();
        translate(position.x, position.y, position.z);

        // Retrieve the sprite sheet with correct generics
        SpriteSheet<BlockType, BlockFace> spriteSheet = world.getSpriteSheet();

        // Get textures for each face
        PImage topTexture = spriteSheet.getSprite(blockType, BlockFace.TOP);
        PImage bottomTexture = spriteSheet.getSprite(blockType, BlockFace.BOTTOM);
        PImage sideTexture = spriteSheet.getSprite(blockType, BlockFace.SIDE);

        // Half size for easier calculations
        float halfSize = size / 2.0f;

        // Enable textures
        textureMode(NORMAL);
        noStroke();

        // Front Face
        beginShape(QUADS);
        texture(sideTexture);
        vertex(-halfSize, -halfSize, halfSize, 0, 0);
        vertex(halfSize, -halfSize, halfSize, 1, 0);
        vertex(halfSize, halfSize, halfSize, 1, 1);
        vertex(-halfSize, halfSize, halfSize, 0, 1);
        endShape();

        // Back Face
        beginShape(QUADS);
        texture(sideTexture);
        vertex(halfSize, -halfSize, -halfSize, 0, 0);
        vertex(-halfSize, -halfSize, -halfSize, 1, 0);
        vertex(-halfSize, halfSize, -halfSize, 1, 1);
        vertex(halfSize, halfSize, -halfSize, 0, 1);
        endShape();

        // Left Face
        beginShape(QUADS);
        texture(sideTexture);
        vertex(-halfSize, -halfSize, -halfSize, 0, 0);
        vertex(-halfSize, -halfSize, halfSize, 1, 0);
        vertex(-halfSize, halfSize, halfSize, 1, 1);
        vertex(-halfSize, halfSize, -halfSize, 0, 1);
        endShape();

        // Right Face
        beginShape(QUADS);
        texture(sideTexture);
        vertex(halfSize, -halfSize, halfSize, 0, 0);
        vertex(halfSize, -halfSize, -halfSize, 1, 0);
        vertex(halfSize, halfSize, -halfSize, 1, 1);
        vertex(halfSize, halfSize, halfSize, 0, 1);
        endShape();

        // Top Face
        beginShape(QUADS);
        texture(topTexture);
        vertex(-halfSize, -halfSize, -halfSize, 0, 0);
        vertex(halfSize, -halfSize, -halfSize, 1, 0);
        vertex(halfSize, -halfSize, halfSize, 1, 1);
        vertex(-halfSize, -halfSize, halfSize, 0, 1);
        endShape();

        // Bottom Face
        beginShape(QUADS);
        texture(bottomTexture);
        vertex(-halfSize, halfSize, halfSize, 0, 0);
        vertex(halfSize, halfSize, halfSize, 1, 0);
        vertex(halfSize, halfSize, -halfSize, 1, 1);
        vertex(-halfSize, halfSize, -halfSize, 0, 1);
        endShape();

        popMatrix();
    }
}


public class Chunk {
    private final int size;
    private final PVector position;
    private final float resolution;
    private final float scale;

    public Chunk(int size, PVector position, float resolution, float scale) {
        this.size = size;
        this.position = position;
        this.resolution = resolution;
        this.scale = scale;
    }

    public void draw() {
        pushMatrix();
        translate(position.x, position.y, position.z);
        box(size * resolution * scale);
        popMatrix();
    }
}


public class World {
    private final List<Block> blocks = new ArrayList<>();
    private final SpriteSheet<BlockType, BlockFace> spriteSheet;

    public World(SpriteSheet<BlockType, BlockFace> spriteSheet) {
        this.spriteSheet = spriteSheet;
    }

    public void setup() {
        int size = 8;
        int planeLength = 100;
        for (int x = 0; x < planeLength; x++) {
            for (int y = 0; y < 1; y++) {
                for (int z = 0; z < planeLength; z++) {
                    PVector position = new PVector(x * size, y * size, z * size);
                    Block block = new Block(this, position, BlockType.GRASS, size);
                    blocks.add(block);
                }
            }
        }
    }

    public void draw() {
        for (Block block : blocks) {
            block.draw();
        }
    }

    protected SpriteSheet<BlockType, BlockFace> getSpriteSheet() {
        return spriteSheet;
    }

    public void tick(float deltaTime) {
        // Placeholder for any time-dependent updates, if needed
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
    float d = 0; // Distance from the origin
    camera(-d, -256, d, 
           256, 0, 256,   // Look at the origin
           0, 1, 0); // Camera up direction
}


// ===========  Pre-setup ===========
World world;
float lastFrameTime = 0;


// ===========  Processing Functions ===========
void setup() {
    fullScreen(P3D);
    noiseSeed(42);

    apply3DCamera();

    // Create the sprite sheet
    SpriteSheet<BlockType, BlockFace> spriteSheet = new EightBitMinecraftSpriteSheet("block-faces.png", 24, 8);

    // Initialize the world with the sprite sheet
    world = new World(spriteSheet);
    world.setup();
}



void draw() {
    float currentTime = millis() / 1000.0; // Convert to seconds
    float deltaTime = currentTime - lastFrameTime;
    lastFrameTime = currentTime;

    background(0, 0, 0);

    lights();
    directionalLight(255, 255, 255, 0, -1, -1);

    world.tick(deltaTime);
    world.draw();

    if (frameCount == 1) {
        save("output/output.tif");
    }

    drawFPS();
}

