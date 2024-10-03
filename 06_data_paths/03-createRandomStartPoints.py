# ---------------------------------------------------------------------------
# Create random start points.
# Author: A. Droghini (adroghini@alaska.edu), Alaska Center for Conservation Science
# Description: Generates 10,000 random points within the convex hull polygons that we created (coarsely representing the home range of individual female moose).
# Purpose: We'll use these points as starting locations for generating 1000 random paths.
# ---------------------------------------------------------------------------

# Import packages
import arcpy
import os

# Set root directory
drive = 'C:\\'
root_folder = 'ACCS_Work\\GMU_17_Moose'

# Set overwrite option
arcpy.env.overwriteOutput = True

# Set workspace
geodatabase = os.path.join(drive, root_folder, 'GIS\\Moose_SouthwestAlaska.gdb')
arcpy.env.workspace = geodatabase

# Define inputs
input_projection = 3338
boundaries = "convexHulls"
number_of_pts = 10000
pts_join_field = "CID" # default name created by CreateRandomPoints function
boundaries_join_field = "OBJECTID"
field_list = ["deployment_id"]

#  Define outputs
output_name = "randomStartPts"

# Set projection
initial_projection = arcpy.SpatialReference(input_projection)

print("Generating random points")
# Create random points within the boundaries of the convex hull polygons that represent moose home ranges
arcpy.CreateRandomPoints_management(out_path=geodatabase, out_name=output_name, constraining_feature_class=boundaries, number_of_points_or_field=number_of_pts)

# Join random points to convex hull polygons by the ID field so we can associate individual moose with points
arcpy.JoinField_management(in_data=output_name, in_field=pts_join_field, join_table=boundaries, join_field=boundaries_join_field, fields=field_list)

# Add coordinate fields
arcpy.AddXY_management(output_name)

print("Complete")