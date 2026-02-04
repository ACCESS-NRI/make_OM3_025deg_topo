#!/usr/bin/env sh
# Copyright 2025 ACCESS-NRI and contributors. See the top-level COPYRIGHT file for details.
# SPDX-License-Identifier: Apache-2.0

#PBS -q normal
#PBS -l walltime=1:00:00
#PBS -l ncpus=14
#PBS -l mem=50GB
#PBS -l wd
#PBS -l storage=gdata/ik11+gdata/tm70+gdata/xp65+gdata/vk83+gdata/x77

# Input files
INPUT_HGRID='/g/data/vk83/configurations/inputs/access-om3/mom/grids/mosaic/global.25km/2025.09.02/ocean_hgrid.nc'
INPUT_VGRID='/g/data/vk83/configurations/inputs/access-om3/mom/grids/vertical/global.25km/2025.03.12/ocean_vgrid.nc'
INPUT_GEBCO='/g/data/ik11/inputs/GEBCO_2024/GEBCO_2024.nc'

# Minimum allowed y-size for a cell (in m)
CUTOFF_VALUE=6000

# Output filenames
# These need to match finalise.sh
ESMF_MESH_FILE='access-om3-25km-ESMFmesh.nc'
ESMF_NO_MASK_MESH_FILE='access-om3-25km-nomask-ESMFmesh.nc'
ROF_WEIGHTS_FILE='access-om3-25km-rof-remap-weights.nc'

# Build bathymetry-tools
./build.sh

module purge
module use /g/data/xp65/public/modules
module load conda/analysis3-25.11
module load nco

set -x # print commands to e file
set -e # exit on error

# Copy and link input files
cp -L --preserve=timestamps "$INPUT_HGRID" ./ocean_hgrid.nc
cp -L --preserve=timestamps "$INPUT_VGRID" ./ocean_vgrid.nc
ln -sf "$INPUT_GEBCO" ./GEBCO_2024.nc

# Convert double precision vgrid to single
./bathymetry-tools/bin/float_vgrid --vgrid ocean_vgrid.nc --vgrid_type mom6

# Interpolate topography on horizontal grid
./bathymetry-tools/bin/topogtools gen_topo -i GEBCO_2024.nc -o topog_new.nc --hgrid ocean_hgrid.nc --tripolar --longitude-offset -100

# Cut off T cells of size less than cutoff value
./bathymetry-tools/bin/topogtools min_dy -i topog_new.nc -o topog_new_min_dy.nc --cutoff "$CUTOFF_VALUE" --hgrid ocean_hgrid.nc

# Fill cells that have a sea area fraction smaller than 0.5
./bathymetry-tools/bin/topogtools fill_fraction -i topog_new_min_dy.nc -o topog_new_fillfraction.nc  --fraction 0.5

# Apply hand-edits (to ensure Black Sea is connected to Mediterranean)
python3 ./bathymetry-tools/editTopo.py --overwrite --nogui --apply edit_025deg_topog.txt --output topog_new_fillfraction_edited.nc topog_new_fillfraction.nc

# Remove seas according to C-grid rules (need this for merge with B-grid version so they both have nans on land)
./bathymetry-tools/bin/topogtools deseas -i topog_new_fillfraction_edited.nc -o topog_new_fillfraction_edited_deseas.nc --grid_type C

# Set maximum/minimum depth (so we have a C-grid-only version for comparison with the merged B- and C-grid topog.nc)
./bathymetry-tools/bin/topogtools min_max_depth -i topog_new_fillfraction_edited_deseas.nc -o topog_new_fillfraction_edited_deseas_mindepth.nc --level 7 --vgrid ocean_vgrid.nc --vgrid_type mom6

# Make a copy for B grid, setting depth:grid_type = "B" so fix_nonadvective will run
ncatted -O --output topog_new_fillfraction_B.nc -a grid_type,depth,o,c,B topog_new_fillfraction_edited_deseas.nc

# Apply hand-edits to ensure Mediterranean Sea, Black Sea, Sea of Azov and Gulf of Riga survive deseas with B-grid rules
python3 ./bathymetry-tools/editTopo.py --overwrite --nogui --apply edit_025deg_topog_Bgrid.txt --output topog_new_fillfraction_B_edited.nc topog_new_fillfraction_B.nc

# Fix B-grid non-advective coastal cells according to B-grid rules
./bathymetry-tools/bin/topogtools fix_nonadvective --coastal-cells --input topog_new_fillfraction_B_edited.nc --output topog_new_fillfraction_B_edited_fixnonadvective.nc --vgrid ocean_vgrid.nc --vgrid_type mom6

# Remove seas in B-grid file according to B-grid rules
./bathymetry-tools/bin/topogtools deseas -i topog_new_fillfraction_B_edited_fixnonadvective.nc -o topog_new_fillfraction_B_edited_fixnonadvective_deseas.nc --grid_type B

# Merge B-grid and C-grid versions, using C-grid in all ice-free regions
./combine_by_mask.py topog_new_fillfraction_edited_deseas.nc topog_new_fillfraction_B_edited_fixnonadvective_deseas.nc B_mask.nc topog_new_fillfraction_merged.nc

# Apply hand-edits (again) - WARNING: avoid edits that create B-grid non-advective cells in ice-prone areas!
python3 ./bathymetry-tools/editTopo.py --overwrite --nogui --apply edit_025deg_topog.txt --output topog_new_fillfraction_merged_edited.nc topog_new_fillfraction_merged.nc

# Remove seas according to C-grid rules
./bathymetry-tools/bin/topogtools deseas -i topog_new_fillfraction_merged_edited.nc -o topog_new_fillfraction_merged_edited_deseas.nc --grid_type C

# Set maximum/minimum depth
./bathymetry-tools/bin/topogtools min_max_depth -i topog_new_fillfraction_merged_edited_deseas.nc -o topog_new_fillfraction_merged_edited_deseas_mindepth.nc --level 7 --vgrid ocean_vgrid.nc --vgrid_type mom6

# Name final topog as topog.nc
cp topog_new_fillfraction_merged_edited_deseas_mindepth.nc topog.nc

# add name and checksum for input files
MD5SUM=$(md5sum $INPUT_HGRID | awk '{print $1}')
ncatted -O -h -a input_file,global,a,c,"$(readlink -f $INPUT_HGRID) (md5sum:$MD5SUM) ; " topog.nc
MD5SUM=$(md5sum "$INPUT_VGRID" | awk '{print $1}')
ncatted -O -h -a input_file,global,a,c,"$(readlink -f $INPUT_VGRID) (md5sum:$MD5SUM) ; " topog.nc
MD5SUM=$(md5sum $INPUT_GEBCO | awk '{print $1}')
ncatted -O -h -a input_file,global,a,c,"$(readlink -f $INPUT_GEBCO) (md5sum:$MD5SUM) ; " topog.nc
MD5SUM=$(md5sum B_mask | awk '{print $1}')
ncatted -O -h -a input_file,global,a,c,"$(readlink -f B_mask.nc) (md5sum:$MD5SUM) ; " topog.nc

# Move intermediate files to a separate directory
OUTPUT_DIR="topography_intermediate_output"
mkdir -p $OUTPUT_DIR
mv topog_new* $OUTPUT_DIR/

# Create land/sea mask - ocean_mask.nc is now an intermediate file used to generate kmt.nc and is not saved in the final output directory.
./bathymetry-tools/bin/topogtools mask -i topog.nc -o ocean_mask.nc

# Add MD5 checksum of topog.nc as a global attribute to ocean_mask.nc
MD5SUM_topog=$(md5sum topog.nc | awk '{print $1}')
ncatted -O -h -a input_file,global,a,c,"$(readlink -f topog.nc) (md5sum:$MD5SUM_topog)" ocean_mask.nc

# Make CICE mask file (`kmt.nc`)
ncrename -O -v mask,kmt ocean_mask.nc kmt.nc
ncks -O -x -v geolon_t,geolat_t kmt.nc kmt.nc #drop unused vars

# Add MD5 checksum as a global attribute to ocean_mask.nc
MD5SUM_mask=$(md5sum ocean_mask.nc | awk '{print $1}')
ncatted -O -h -a ocean_mask_file,global,a,c,"$(readlink -f ocean_mask.nc) (md5sum:$MD5SUM_mask)" kmt.nc

# Remove the intermediate ocean_mask.nc
rm -f ocean_mask.nc

# Create ESMF mesh from hgrid and topog.nc
python3 ./om3-scripts/mesh_generation/generate_mesh.py --grid-type=mom --grid-filename=ocean_hgrid.nc --mesh-filename="$ESMF_MESH_FILE" --topog-filename=topog.nc --wrap-lons True

# Create ESMF mesh without mask
python3 ./om3-scripts/mesh_generation/generate_mesh.py --grid-type=mom --grid-filename=ocean_hgrid.nc --mesh-filename="$ESMF_NO_MASK_MESH_FILE" --wrap-lons True

# Create runoff remapping weights
python3 ./om3-scripts/mesh_generation/generate_rof_weights.py --mesh_filename="$ESMF_MESH_FILE" --weights_filename="$ROF_WEIGHTS_FILE"
