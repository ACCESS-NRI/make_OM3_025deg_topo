# make_OM3_025deg_topo

Makes 0.25-degree (25km) `topog.nc` MOM6 global bathymetry file for [ACCESS-OM3-25km](https://github.com/ACCESS-NRI/access-om3-configs/tree/release-MC_25km_jra_iaf), based on the GEBCO 2024 dataset.

The workflow [`gen_topo.sh`](https://github.com/ACCESS-NRI/make_OM3_025deg_topo/blob/main/gen_topo.sh) contains many steps, and stores intermediate files in `topography_intermediate_output` so you can check the result of each step. Key stages in the processing are:
- Interpolate GEBCO onto the model grid, setting each cell's altitude to the mean of the GEBCO data within it and setting cells that contain more than 50% land in GEBCO to 100% land in the model (this rule of thumb gives acceptable results in most places but requires some specific fixes to ensure important straits, sills, etc. are well represented).
- Create two global topographies, one (`topog_new_fillfraction_edited_deseas.nc`) with a coastline suitable for a C-grid (i.e. with 1-cell-wide channels) and another (`topog_new_fillfraction_B_edited_fixnonadvective_deseas.nc`) with a coastline suitable for both a B-grid and C-grid (i.e. all 1-cell-wide channels are closed off or widened to at least 2 cells); these are identical apart from coastal points and any embayments/channels that are cut off by closing 1-cell-wide channels in the B-grid version.
- These are then merged with `combine_by_mask.py` using the mask `B_mask.nc` such the B-grid version is used in regions prone to sea ice and the C-grid version everywhere else. This allows the use of B-grid CICE6 with C-grid MOM6 without [ice piling up](https://github.com/ACCESS-NRI/access-om3-configs/issues/1010) in narrow channels and inlets.
- Further processing and edits to generate the final `topog.nc`.
- Generation of associated .nc files based on and consistent with `topog.nc`.

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

3. **Generate Topography**
   Use `./gen_topo.sh` to generate the topography and associated files. For 0.25-degree (25km) resolution or finer, this will require submission via `qsub`.

   - add gdata for your project & working directory to the `#PBS -l storage=` line in `gen_topo.sh`
   - check/adjust `INPUT_HGRID`, `INPUT_VGRID` and `INPUT_GEBCO` in both `gen_topo.sh` and `finalise.sh`
   - submit the script:
   ```bash
   qsub gen_topo.sh
   ```

4. **Check the output files look OK**

   - See whether the final topography `topog.nc` and associated .nc files look OK. Look carefully for any missing marginal seas, and channels that are too wide or narrow/closed. If there's a problem, you can identify where it arose by inspecting the intermediate outputs in `topography_intermediate_output`.
   - Run `non-advective.ipynb` on ARE to see the B-grid changes in the polar coastlines, and check there are no seas/bays without B-grid advective connection to the ocean in `topography_intermediate_output/topog_new_fillfraction_B_edited_fixnonadvective_deseas.nc`.

5. **Fix problems (if any)**

   Since all outputs are generated from `topog.nc`, problems in any of the outputs can generally be fixed by altering the edits applied as part of generating `topog.nc` in the workflow. There are two files containing lists of edits, which are applied by `editTopo.py` in [`gen_topo.sh`](https://github.com/ACCESS-NRI/make_OM3_025deg_topo/blob/main/gen_topo.sh):
   - `edit_025deg_topog.txt` is applied twice, once to the precursor to the B- and C-grid files which are later merged, and then again to the merged file.
   - `edit_025deg_topog_Bgrid.txt` is applied only to the B-grid file prior to merging but after the first application of `edit_025deg_topog.txt`. This should apply fixes that are suitable for a global B-grid, e.g. to open the Bosphorus so the Black Sea is retained.
   - Run `bathymetry-tools/editTopo.py` on the appropriate intermediate files to generate new lists of edits which can be appended (with explanatory comments) to `edit_025deg_topog.txt` or `edit_025deg_topog_Bgrid.txt` to make them part of the workflow.
   - Return to step 3 to check that the updated workflow does what you want.

5. **Finalise Output Files**

   Once the output files meet your satisfaction, commit and push the changes, then run `finalise.sh` to add the git commit hash as metadata in the output `.nc` files for provenance.

## Note on Dependencies  

This workflow relies on the **xp65 conda environments** for running the scripts and generating the outputs. As long as you are [a member of the _xp65_ project](https://my.nci.org.au/mancini/project/xp65/members/active), this conda environment is loaded as part of the scripts.
