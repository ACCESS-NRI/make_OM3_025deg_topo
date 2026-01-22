# make_OM3_025deg_topo

Makes 0.25-degree (25km) `topog.nc` MOM6 global bathymetry file for [ACCESS-OM3-25km](https://github.com/ACCESS-NRI/access-om3-configs/tree/release-MC_25km_jra_iaf), based on the GEBCO 2024 dataset.

## Workflow Overview

1. **Download to Gadi**
   This repository contains submodules, so clone with
   ```bash
   git clone --recursive https://github.com/ACCESS-NRI/make_OM3_025deg_topo.git
   ```

2. **Generate Topography:**
   Use `./gen_topog.sh` to generate the topography and associated files. For 0.25-degree resolution or higher, this will require submission via `qsub`.

   - add gdata for your project & working directory to the `#PBS -l storage=` line in `gen_topo.sh`.
   - check/adjust `INPUT_HGRID`, `INPUT_VGRID` and `INPUT_GEBCO` in `gen_topo.sh`.
   - use the `qsub` command to submit the script:
   ```bash
   qsub gen_topo.sh
   ```

3. **Finalize Output Files:**
   Once the output files meet your satisfaction, commit and push the changes, then run `finalise.sh` to add the git commit hash as metadata in the output `.nc` files for provenance.

## Note on Dependencies  

This workflow relies on the **xp65 conda environments** for running the scripts and generating the outputs. As long as you are a member of the _xp65_ project, this conda environment is loaded as part of the scripts.
