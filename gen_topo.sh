#!/usr/bin/env sh
#PBS -P tm70
#PBS -q normal
#PBS -l walltime=4:00:00,mem=4GB
#PBS -l wd
#PBS -lstorage=gdata/hh5+gdata/ik11+gdata/tm70

module use /g/data/hh5/public/modules
module load conda/analysis3

# Build domain-tools
./build.sh

set -x
set -e

cp -L --preserve=timestamps /g/data/tm70/ek4684/New_grid_input_files_025deg_75zlevels/ocean_hgrid.nc .
cp -L --preserve=timestamps /g/data/tm70/ek4684/New_grid_input_files_025deg_75zlevels/ocean_vgrid.nc .
ln -sf /g/data/ik11/inputs/GEBCO_2024/GEBCO_2024.nc ./

# Convert double precision vgrid to single
./domain-tools/bin/float_vgrid --vgrid ocean_vgrid.nc --vgrid_type mom6

# Interpolate topography on horizontal grid:
# ./domain-tools/bin/topogtools gen_topo -i GEBCO_2024.nc -o topog_new.nc --hgrid ocean_hgrid.nc --tripolar --longitude-offset -100 

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
ncrename -O -v mask,kmt ocean_mask.nc kmt.nc 

# Create ESMF mesh from hgrid and ocean_mask.nc
python3 ./om3-scripts/mesh_generation/generate_mesh.py --grid-type=mom --grid-filename=ocean_hgrid.nc --mesh-filename=access-om2-025deg-ESMFmesh.nc --mask-filename=ocean_mask.nc --wrap-lons

# Create ESMF mesh without mask
python3 ./om3-scripts/mesh_generation/generate_mesh.py --grid-type=mom --grid-filename=ocean_hgrid.nc --mesh-filename=access-om2-025deg-nomask-ESMFmesh.nc --wrap-lons
