# 3D World

Welcome to the 3D World project! This is my first-ever program created in Processing, and I decided to challenge myself by building a 3D world from scratch. The world features dynamically generated terrain, trees with autumn foliage, water bodies, fluffy clouds, and rocky mountains. All objects are procedurally generated and rendered in 3D using Processing's P3D mode.

## Features

- Procedurally Generated Terrain: The terrain is generated using Perlin noise, which provides a natural and organic look. The heights of different terrain points create valleys, hills, and mountains.

- Dynamic Object System: A flexible object-oriented design allows for the creation and management of various types of objects in the world (trees, clouds, etc.) by extending a base class WorldObject.

- Trees with Autumn Foliage: The world features trees with randomly colored autumn leaves, ranging from greens to oranges and reds. Each tree is generated with a trunk and foliage in 3D.

- Fluffy Clouds: The sky contains randomly placed fluffy clouds made up of overlapping 3D ellipsoids. Their positions and shapes are precomputed to avoid jittering, giving a consistent and natural look to the sky.

- Rocky Mountains: Terrain that rises above a certain height is marked as rocky, adding texture and diversity to the landscape.

- Water Bodies: Bodies of water appear at lower elevations, giving the world lakes or oceans, adding to the realism.

- Lighting and Camera: A dynamic lighting system adds depth to the 3D objects. The camera is set up to give a nice perspective view of the world.

## Project Structure

Todo
