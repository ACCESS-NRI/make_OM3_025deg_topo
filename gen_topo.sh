#!/usr/bin/env sh
#PBS -q normal
#PBS -l walltime=4:00:00,mem=4GB
#PBS -l wd
#PBS -lstorage=gdata/hh5+gdata/ik11

# Ensure build.sh is executable
if [ ! -x "./build.sh" ]; then
  chmod +x ./build.sh
fi

# Build domain-tools
./build.sh

module use /g/data/hh5/public/modules
module load conda/analysis3
module load nco

set -x
set -e

# Using the environment variables passed via -v
INPUT_HGRID=$INPUT_HGRID
INPUT_VGRID=$INPUT_VGRID
INPUT_GBCO=$INPUT_GBCO

# Copy and link input files
cp -L --preserve=timestamps "$INPUT_HGRID" ./ocean_hgrid.nc
cp -L --preserve=timestamps "$INPUT_VGRID" ./ocean_vgrid.nc
ln -sf "$INPUT_GBCO" ./GEBCO_2024.nc

# Convert double precision vgrid to single
./domain-tools/bin/float_vgrid --vgrid ocean_vgrid.nc --vgrid_type mom6

# Interpolate topography on horizontal grid:
./domain-tools/bin/topogtools gen_topo -i GEBCO_2024.nc -o topog_new.nc --hgrid ocean_hgrid.nc --tripolar --longitude-offset -100 

# Cut off T cells of size less than 6kms (6000 m)
./domain-tools/bin/topogtools min_dy -i topog_new.nc -o topog_new_min_dy.nc --cutoff 6000 --hgrid ocean_hgrid.nc

# Fill cells that have a sea area fraction smaller than 0.5:
./domain-tools/bin/topogtools fill_fraction -i topog_new_min_dy.nc -o topog_new_fillfraction.nc  --fraction 0.5

# edit_topo.py
python ./topogtools/editTopo.py --overwrite --nogui --apply edit_topog_new_fillfraction.txt --output topog_new_fillfraction_edited.nc topog_new_fillfraction.nc

# Remove seas:
./domain-tools/bin/topogtools deseas -i topog_new_fillfraction_edited.nc -o topog_new_fillfraction_edited_deseas.nc --grid_type C

# Set maximum/minimum depth
./domain-tools/bin/topogtools min_max_depth -i topog_new_fillfraction_edited_deseas.nc -o topog_new_fillfraction_edited_deseas_mindepth.nc --level 4 --vgrid ocean_vgrid.nc --vgrid_type mom6

# Create land/sea mask
cp topog_new_fillfraction_edited_deseas_mindepth.nc topog.nc
./domain-tools/bin/topogtools mask -i topog.nc -o ocean_mask.nc

# Calculate MD5 checksum for topog.nc
MD5SUM_topog=$(md5sum topog.nc | awk '{print $1}')

# Add MD5 checksum as a global attribute to topog.nc
ncatted -O -h -a md5_checksum,global,a,c,"$MD5SUM_topog" topog.nc

# Calculate MD5 checksum for ocean_mask.nc
MD5SUM_mask=$(md5sum ocean_mask.nc | awk '{print $1}')

# Add MD5 checksum as a global attribute to ocean_mask.nc
ncatted -O -h -a md5_checksum,global,a,c,"$MD5SUM_mask" ocean_mask.nc

# Make CICE mask file (`kmt.nc`) 
ncrename -O -v mask,kmt ocean_mask.nc kmt.nc 

#Move intermediate files to a separate directory
OUTPUT_DIR="topography_output"
mkdir -p $OUTPUT_DIR

# Move all intermediate files to topography_output directory
mv topog_new.nc $OUTPUT_DIR/
mv topog_new_min_dy.nc $OUTPUT_DIR/
mv topog_new_fillfraction.nc $OUTPUT_DIR/
mv topog_new_fillfraction_edited.nc $OUTPUT_DIR/
mv topog_new_fillfraction_edited_deseas.nc $OUTPUT_DIR/
mv topog_new_fillfraction_edited_deseas_mindepth.nc $OUTPUT_DIR/

# Create ESMF mesh from hgrid and ocean_mask.nc
python3 ./om3-scripts/mesh_generation/generate_mesh.py --grid-type=mom --grid-filename=ocean_hgrid.nc --mesh-filename=access-om3-025deg-ESMFmesh.nc --mask-filename=ocean_mask.nc --wrap-lons

# Create ESMF mesh without mask
python3 ./om3-scripts/mesh_generation/generate_mesh.py --grid-type=mom --grid-filename=ocean_hgrid.nc --mesh-filename=access-om3-025deg-nomask-ESMFmesh.nc --wrap-lons
