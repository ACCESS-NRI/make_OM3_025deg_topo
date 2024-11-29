# make_OM3_025deg_topo

Make 0.25-degree `topog.nc` MOM bathymetry file from the GEBCO 2024 dataset.

## Workflow Overview

1. **Generate Topography:**  
   Run `./gen_topog.sh` to generate the topography and associated files. For 0.25-degree resolution or higher, this will require submission via `qsub`.

2. **Finalize Output Files:**  
   Once the output files meet your satisfaction, commit and push the changes, then add the git commit hash as metadata in the output `.nc` files by running `finalise.sh`.

3. **Submitting the Script:**  
   Use the `qsub` command to submit the script, passing the required input files as arguments. For example:  
   ```bash
   qsub -v INPUT_HGRID="/path/to/ocean_hgrid.nc",INPUT_VGRID="/path/to/ocean_vgrid.nc",INPUT_GBCO="/path/to/GEBCO_2024.nc" gen_topo.sh
   ```

## Note on Dependencies  

This workflow relies on the **hh5 conda environments** for running the scripts and generating the outputs. Ensure that the required conda environment is active before executing the workflow.

--- 