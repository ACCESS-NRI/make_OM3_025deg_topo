#!/usr/bin/env sh
# Copyright 2025 ACCESS-NRI and contributors. See the top-level COPYRIGHT file for details.
# SPDX-License-Identifier: Apache-2.0
#
# Commit changes and push, then add metadata to note how changes were made

echo "About to commit all changes to git repository and push to remote."
read -p "Proceed? (y/n) " yesno
case $yesno in
   [Yy] ) ;;
      * ) echo "Cancelled."; exit 0;;
esac

set -x
set -e

module load nco
module load git

# These need to match gen_topo.sh
ESMF_MESH_FILE='access-om3-25km-ESMFmesh.nc'
ESMF_NO_MASK_MESH_FILE='access-om3-25km-nomask-ESMFmesh.nc'
ROF_WEIGHTS_FILE='access-om3-25km-rof-remap-weights.nc'

git commit -am "Files used for topo generation on $(date)" || true
git push || true

ncatted -O -h -a history,global,a,c," | Created on $(date) using https://github.com/ACCESS-NRI/make_OM3_025deg_topo/tree/$(git rev-parse --short HEAD) and based on GEBCO_2024 topography" topog.nc
ncatted -O -h -a history,global,a,c," | Created on $(date) using https://github.com/ACCESS-NRI/make_OM3_025deg_topo/tree/$(git rev-parse --short HEAD)" kmt.nc
ncatted -O -h -a history,global,a,c," | Updated on $(date) using https://github.com/ACCESS-NRI/make_OM3_025deg_topo/tree/$(git rev-parse --short HEAD)" ocean_vgrid.nc
ncatted -O -h -a history,global,a,c," | Created on $(date) using https://github.com/ACCESS-NRI/make_OM3_025deg_topo/tree/$(git rev-parse --short HEAD)" $ESMF_MESH_FILE
ncatted -O -h -a history,global,a,c," | Created on $(date) using https://github.com/ACCESS-NRI/make_OM3_025deg_topo/tree/$(git rev-parse --short HEAD)" $ESMF_NO_MASK_MESH_FILE
ncatted -O -h -a history,global,a,c," | Created on $(date) using https://github.com/ACCESS-NRI/make_OM3_025deg_topo/tree/$(git rev-parse --short HEAD)" $ROF_WEIGHTS_FILE
