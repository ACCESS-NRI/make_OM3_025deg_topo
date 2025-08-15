#!/usr/bin/env sh
# Copyright 2025 ACCESS-NRI and contributors. See the top-level COPYRIGHT file for details.
# SPDX-License-Identifier: Apache-2.0
#
# Commit changes and push, then add metadata to note how changes were made 

module load nco
module load git

# echo "About to commit all changes to git repository and push to remote."
# read -p "Proceed? (y/n) " yesno
# case $yesno in
#    [Yy] ) ;;
#       * ) echo "Cancelled."; exit 0;;
# esac

set -x
set -e

git commit -am "Files used for topo/mask generation on $(date)" || true
git push || true

ncatted -O -h -a history,global,a,c," | Created on $(date) using https://github.com/ACCESS-NRI/make_OM3_025deg_topo/tree/$(git rev-parse --short HEAD)" topog.nc
ncatted -O -h -a history,global,a,c," | Created on $(date) using https://github.com/ACCESS-NRI/make_OM3_025deg_topo/tree/$(git rev-parse --short HEAD)" kmt.nc
ncatted -O -h -a history,global,a,c," | Updated on $(date) using https://github.com/ACCESS-NRI/make_OM3_025deg_topo/tree/$(git rev-parse --short HEAD)" ocean_vgrid.nc

ncatted -O -h -a history,global,a,c," and based on GEBCO_2024 topography" topog.nc

