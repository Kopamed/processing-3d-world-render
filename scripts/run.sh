#!/bin/bash

# Create a temporary folder for the sketch
mkdir sketch_folder

# Move and rename the .pde file to the new sketch_folder
cp sketch_3d_world_render.pde sketch_folder/sketch_folder.pde

# Run the processing-java command
processing-java --sketch=$(pwd)/sketch_folder --output=$(pwd)/output --force --run

# Copy the generated output file to the project root
cp sketch_folder/output/output.tif $(pwd)/images/output.tif

# Cleanup: remove the temporary sketch_folder and output folder
rm -rf sketch_folder output
