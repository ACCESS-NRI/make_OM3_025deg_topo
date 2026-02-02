# make_OM3_025deg_topo

Makes 0.25-degree (25km) `topog.nc` MOM6 global bathymetry file for [ACCESS-OM3-25km](https://github.com/ACCESS-NRI/access-om3-configs/tree/release-MC_25km_jra_iaf), based on the GEBCO 2024 dataset.

## Workflow Overview

1. **Download to Gadi**
   This repository contains submodules, so clone with
   ```bash
   git clone --recursive https://github.com/ACCESS-NRI/make_OM3_025deg_topo.git
   cd make_OM3_025deg_topo
   ```

2. (optional) **Regenerate B-grid mask**
   `B_mask.nc` can be updated with `make_B_mask.ipynb` if needed

   - run `make_B_mask.ipynb` on ARE and check it looks like what you want
   - move `~/B_mask.nc` to topog generation directory so it can be used in workflow
   - run `finalise_B_mask.sh` to embed its provenance

3. **Generate Topography:**
   Use `./gen_topo.sh` to generate the topography and associated files. For 0.25-degree resolution or higher, this will require submission via `qsub`.

   - add gdata for your project & working directory to the `#PBS -l storage=` line in `gen_topo.sh`
   - check/adjust `INPUT_HGRID`, `INPUT_VGRID` and `INPUT_GEBCO` in `gen_topo.sh` and `finalise.sh`
   - submit the script:
   ```bash
   qsub gen_topo.sh
   ```

4. **Check the output files look OK**
   - Run `non-advective.ipynb` to check there are no seas/bays without advective connection to the ocean in `topography_intermediate_output/topog_new_fillfraction_B_fixnonadvective_deseas.nc`.
   - You can edit offending points in `topog.nc` (if any) with `bathymetry-tools/editTopo.py` and append your edits (and explanatory comments) to `edit_025deg_topog_new_fillfraction.txt` to make them part of the workflow, then going back to step 3

5. **Finalise Output Files:**
   Once the output files meet your satisfaction, commit and push the changes, then run `finalise.sh` to add the git commit hash as metadata in the output `.nc` files for provenance.

## Note on Dependencies  

This workflow relies on the **xp65 conda environments** for running the scripts and generating the outputs. As long as you are [a member of the _xp65_ project](https://my.nci.org.au/mancini/project/xp65/members/active), this conda environment is loaded as part of the scripts.
