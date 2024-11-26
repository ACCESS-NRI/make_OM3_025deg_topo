module purge
module load intel-compiler 
module load netcdf

cd ./domain-tools/


# Check if the build directory exists before cleaning
if [ -d "build" ]; then
  cmake --build build --target clean
fi

cmake -B build -DCMAKE_BUILD_TYPE=Release -DNetCDF_Fortran_LIBRARY=$NETCDF_ROOT/lib/Intel/libnetcdff.so -DNetCDF_C_LIBRARY=$NETCDF_ROOT/lib/libnetcdf.so -DNetCDF_Fortran_INCLUDE_DIRS=$NETCDF_ROOT/include/Intel  

cmake --build build

cmake --install build --prefix=./

cd ../
