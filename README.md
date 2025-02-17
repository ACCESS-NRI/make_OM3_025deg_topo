# make_OM3_025deg_topo

Make 0.25-degree `topog.nc` MOM bathymetry file from the GEBCO 2024 dataset.

## Workflow Overview

1. **Generate Topography:**  
   Use `./gen_topog.sh` to generate the topography and associated files. For 0.25-degree resolution or higher, this will require submission via `qsub`.

   First, add gdata for your project & working directory to the `#PBS -l storage=` line in `get_topo.sh`

   Then, use the `qsub` command to submit the script, passing the required input files as arguments. For example:  
   ```bash
   qsub -v INPUT_HGRID="/path/to/ocean_hgrid.nc",INPUT_VGRID="/path/to/ocean_vgrid.nc",INPUT_GBCO="/path/to/GEBCO_2024.nc" -P $PROJECT gen_topo.sh
   ```

2. **Finalize Output Files:**  
   Once the output files meet your satisfaction, commit and push the changes, then add the git commit hash as metadata in the output `.nc` files by running `finalise.sh`.

## Note on Dependencies  

This workflow relies on the **hh5 conda environments** for running the scripts and generating the outputs. As long as you are a member of the _hh5_ project, this conda environment is loaded as part of the scripts.

--- 

qsub -v INPUT_HGRID=/g/data/vk83/prerelease/configurations/inputs/access-om3/mom/grids/mosaic/global.025deg/2025.01.30/ocean_hgrid.nc,INPUT_VGRID=/g/data/vk83/prerelease/configurations/inputs/access-om3/mom/grids/vertical/global.025deg/2025.01.30/ocean_vgrid.nc,INPUT_GBCO=/g/data/ik11/inputs/GEBCO_2024/GEBCO_2024.nc -P $PROJECT gen_topo.sh