#!/usr/bin/env sh
# Copyright 2025 ACCESS-NRI and contributors. See the top-level COPYRIGHT file for details.
# SPDX-License-Identifier: Apache-2.0
#
# Commit changes and push, then add metadata to note how changes were made

echo "About to commit B_mask changes to git repository and push to remote."
read -p "Was B_mask.nc created by the current version of make_B_mask.ipynb? (y/n) " yesno
case $yesno in
   [Yy] ) ;;
      * ) echo "Cancelled."; exit 0;;
esac

set -x
set -e

module load nco
module load git

git add make_B_mask.ipynb
git commit -m "make_B_mask.ipynb on $(date)" || true
git push || true

ncatted -O -h -a history,global,a,c," | Created on $(date) using https://github.com/ACCESS-NRI/make_OM3_025deg_topo/tree/$(git rev-parse --short HEAD)/make_B_mask.ipynb" B_mask.nc

git add B_mask.nc
git commit -m "B_mask.nc on $(date)" || true
git push || true
