# make_OM3_025deg_topo

Make 0.25 degree topog.nc MOM bathymetry file from GEBCO 2024 dataset.

./gen_topog.sh will generate topography and associated files. For 0.25deg resolution and higher this will require qsub.

When the output files are to your satisfaction, commit and push your changes and add the git commit hash as metadata in the output .nc files by running finalise.sh.

Use the qsub command to submit the script, passing the required input files as arguments, For example:

qsub -v INPUT_HGRID="/path/to/ocean_hgrid.nc",INPUT_VGRID="/path/to/ocean_vgrid.nc",INPUT_GBCO="/path/to/GEBCO_2024.nc" gen_topo.sh

