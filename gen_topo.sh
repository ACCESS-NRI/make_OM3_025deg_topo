#!/usr/bin/env sh
# Copyright 2023 ACCESS-NRI and contributors. See the top-level COPYRIGHT file for details.
# SPDX-License-Identifier: Apache-2.0

#PBS -q normal
#PBS -l walltime=4:00:00,mem=10GB
#PBS -l wd
#PBS -l storage=gdata/hh5+gdata/ik11+gdata/tm70

# Input files - Using the environment variables passed via -v
INPUT_HGRID=$INPUT_HGRID
INPUT_VGRID=$INPUT_VGRID
INPUT_GBCO=$INPUT_GBCO
# Minimum allowed y-size for a cell (in m)
CUTOFF_VALUE=6000
# Output filenames
ESMF_MESH_FILE='access-om3-025deg-ESMFmesh.nc'
ESMF_NO_MASK_MESH_FILE='access-om3-025deg-nomask-ESMFmesh.nc' 


# Build domain-tools
./build.sh

module purge
module use /g/data/hh5/public/modules
module load conda/analysis3
module load nco

set -x #print commands to e file
set -e #exit on error

# Copy and link input files
cp -L --preserve=timestamps "$INPUT_HGRID" ./ocean_hgrid.nc
cp -L --preserve=timestamps "$INPUT_VGRID" ./ocean_vgrid.nc
ln -sf "$INPUT_GBCO" ./GEBCO_2024.nc

# Convert double precision vgrid to single
./domain-tools/bin/float_vgrid --vgrid ocean_vgrid.nc --vgrid_type mom6

# Interpolate topography on horizontal grid:
./domain-tools/bin/topogtools gen_topo -i GEBCO_2024.nc -o topog_new.nc --hgrid ocean_hgrid.nc --tripolar --longitude-offset -100 

# Cut off T cells of size less than cutoff value
./domain-tools/bin/topogtools min_dy -i topog_new.nc -o topog_new_min_dy.nc --cutoff "$CUTOFF_VALUE" --hgrid ocean_hgrid.nc

# Fill cells that have a sea area fraction smaller than 0.5:
./domain-tools/bin/topogtools fill_fraction -i topog_new_min_dy.nc -o topog_new_fillfraction.nc  --fraction 0.5

# edit_topo.py
python ./topogtools/editTopo.py --overwrite --nogui --apply edit_025deg_topog_new_fillfraction.txt --output topog_new_fillfraction_edited.nc topog_new_fillfraction.nc

# Remove seas:
./domain-tools/bin/topogtools deseas -i topog_new_fillfraction_edited.nc -o topog_new_fillfraction_edited_deseas.nc --grid_type C

# Set maximum/minimum depth
./domain-tools/bin/topogtools min_max_depth -i topog_new_fillfraction_edited_deseas.nc -o topog_new_fillfraction_edited_deseas_mindepth.nc --level 4 --vgrid ocean_vgrid.nc --vgrid_type mom6

# Name final topog as topo.nc
cp topog_new_fillfraction_edited_deseas_mindepth.nc topog.nc
# add name and checksum for input files
MD5SUM=$(md5sum ocean_hgrid.nc | awk '{print $1}')
ncatted -O -h -a input_file,global,a,c,"$(readlink -f $INPUT_HGRID) (md5sum:$MD5SUM) ; " topog.nc
MD5SUM=$(md5sum ocean_vgrid.nc | awk '{print $1}')
ncatted -O -h -a input_file,global,a,c,"$(readlink -f $INPUT_VGRID) (md5sum:$MD5SUM) ; " topog.nc
MD5SUM=$(md5sum GEBCO_2024.nc | awk '{print $1}')
ncatted -O -h -a input_file,global,a,c,"$(readlink -f $INPUT_GBCO) (md5sum:$MD5SUM) ; " topog.nc

#Move intermediate files to a separate directory
OUTPUT_DIR="topography_intermediate_output"
mkdir -p $OUTPUT_DIR
mv topog_new* $OUTPUT_DIR/

# Create land/sea mask
./domain-tools/bin/topogtools mask -i topog.nc -o ocean_mask.nc

# Add MD5 checksum as a global attribute to topog.nc
MD5SUM_topog=$(md5sum topog.nc | awk '{print $1}')
ncatted -O -h -a input_file,global,a,c,"$(readlink -f topog.nc) (md5sum:$MD5SUM_topog)" ocean_mask.nc

# Make CICE mask file (`kmt.nc`) 
ncrename -O -v mask,kmt ocean_mask.nc kmt.nc 
ncks -O -x -v geolon_t,geolat_t kmt.nc kmt.nc #drop unused vars

# Add MD5 checksum as a global attribute to ocean_mask.nc
MD5SUM_mask=$(md5sum ocean_mask.nc | awk '{print $1}')
ncatted -O -h -a ocean_mask_file,global,a,c,"$(readlink -f ocean_mask.nc) (md5sum:$MD5SUM_mask)" kmt.nc

# Create ESMF mesh from hgrid and ocean_mask.nc
python3 ./om3-scripts/mesh_generation/generate_mesh.py --grid-type=mom --grid-filename=ocean_hgrid.nc --mesh-filename="$ESMF_MESH_FILE" --mask-filename=ocean_mask.nc --wrap-lons

# Create ESMF mesh without mask
python3 ./om3-scripts/mesh_generation/generate_mesh.py --grid-type=mom --grid-filename=ocean_hgrid.nc --mesh-filename="$ESMF_NO_MASK_MESH_FILE" --wrap-lons
