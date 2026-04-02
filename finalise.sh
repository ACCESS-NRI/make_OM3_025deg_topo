#!/usr/bin/env sh
# Copyright 2025 ACCESS-NRI and contributors. See the top-level COPYRIGHT file for details.
# SPDX-License-Identifier: Apache-2.0
#
# Commit changes and push, then add metadata to note how changes were made

DEFAULT_RESOLUTION="${DEFAULT_RESOLUTION:-25km}"
RESOLUTION_INPUT="${1:-${RESOLUTION:-$DEFAULT_RESOLUTION}}"

usage() {
    echo "Usage: $0 [25km|100km]" >&2
    echo "Set RESOLUTION=25km or RESOLUTION=100km to use qsub -v instead of a positional argument." >&2
}

case "$(printf '%s' "$RESOLUTION_INPUT" | tr '[:upper:]' '[:lower:]')" in
    25km|025deg|0.25deg)
        RESOLUTION='25km'
        ESMF_MESH_FILE='access-om3-25km-ESMFmesh.nc'
        ESMF_NO_MASK_MESH_FILE='access-om3-25km-nomask-ESMFmesh.nc'
        ROF_WEIGHTS_FILE='access-om3-25km-rof-remap-weights.nc'
        ;;
    100km)
        RESOLUTION='100km'
        ESMF_MESH_FILE='access-om3-100km-ESMFmesh.nc'
        ESMF_NO_MASK_MESH_FILE='access-om3-100km-nomask-ESMFmesh.nc'
        ROF_WEIGHTS_FILE='access-om3-100km-rof-remap-weights.nc'
        ;;
    *)
        usage
        exit 1
        ;;
esac

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

git commit -am "Files used for topo generation on $(date)" || true
git push || true

ncatted -O -h -a history,global,a,c," | Created on $(date) using https://github.com/ACCESS-NRI/make_OM3_025deg_topo/tree/$(git rev-parse --short HEAD) and based on GEBCO_2024 topography" topog.nc
ncatted -O -h -a history,global,a,c," | Created on $(date) using https://github.com/ACCESS-NRI/make_OM3_025deg_topo/tree/$(git rev-parse --short HEAD)" kmt.nc
ncatted -O -h -a history,global,a,c," | Updated on $(date) using https://github.com/ACCESS-NRI/make_OM3_025deg_topo/tree/$(git rev-parse --short HEAD)" ocean_vgrid.nc
ncatted -O -h -a history,global,a,c," | Created on $(date) using https://github.com/ACCESS-NRI/make_OM3_025deg_topo/tree/$(git rev-parse --short HEAD)" $ESMF_MESH_FILE
ncatted -O -h -a history,global,a,c," | Created on $(date) using https://github.com/ACCESS-NRI/make_OM3_025deg_topo/tree/$(git rev-parse --short HEAD)" $ESMF_NO_MASK_MESH_FILE
ncatted -O -h -a history,global,a,c," | Created on $(date) using https://github.com/ACCESS-NRI/make_OM3_025deg_topo/tree/$(git rev-parse --short HEAD)" $ROF_WEIGHTS_FILE

for file in topog.nc kmt.nc ocean_vgrid.nc "$ESMF_MESH_FILE" "$ESMF_NO_MASK_MESH_FILE" "$ROF_WEIGHTS_FILE"; do
    ncatted -O -h -a resolution,global,o,c,"$RESOLUTION" "$file"
done
