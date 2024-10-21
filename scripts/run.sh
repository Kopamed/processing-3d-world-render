#!/bin/bash

# Create a temporary folder for the sketch
mkdir sketch_folder

# Move and rename the .pde file to the new sketch_folder
cp sketch_3d_world_render.pde sketch_folder/sketch_folder.pde

# Run the processing-java command
processing-java --sketch=$(pwd)/sketch_folder --output=$(pwd)/output --force --run || true

# Get the current date and time in a safe format for file names
datetime=$(date +"%Y-%m-%d_%H-%M-%S")

# Copy the generated output file to the project root and rename it
cp sketch_folder/output/output.tif $(pwd)/images/world_$datetime.tif

# Cleanup: remove the temporary sketch_folder and output folder
rm -rf sketch_folder output
