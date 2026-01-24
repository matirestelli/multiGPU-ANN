#!/bin/bash

PROJECT_DIR=$HOME/hpps25-NNdescentNCCL/multigpu-ann

export CUDA_cublas_LIBRARY="/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-24.5-torlmnyzcexnrs6pq4cccabv7ehkv3xy/Linux_x86_64/24.5/math_libs/lib64/libcublas.so"
export CUDA_curand_LIBRARY="/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-24.5-torlmnyzcexnrs6pq4cccabv7ehkv3xy/Linux_x86_64/24.5/math_libs/lib64/libcurand.so"

## change CMakefile.txt to: target_link_libraries(gknng PRIVATE knncuda $ENV{CUDA_cublas_LIBRARY} $ENV{CUDA_curand_LIBRARY})

module purge
module load profile/candidate
module load nvhpc/24.5 
##module load hpcx-mpi/2.19--nvhpc--24.5
module load hpcx-mpi/2.19
module load python/3.11.6--gcc--8.5.0



##export PATH=$HOME/.local/bin:$PATH
export LD_LIBRARY_PATH=/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-24.5-torlmnyzcexnrs6pq4cccabv7ehkv3xy/Linux_x86_64/24.5/REDIST/cuda/12.4/targets/x86_64-linux/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/leonardo/prod/spack/06/install/0.22/linux-rhel8-icelake/gcc-8.5.0/nvhpc-24.5-torlmnyzcexnrs6pq4cccabv7ehkv3xy/Linux_x86_64/24.5/cuda/lib64:$LD_LIBRARY_PATH

# Check if pip exists
python3 -m pip --version > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Installing pip..."
    python3 -m ensurepip --upgrade
fi

# Now install matplotlib & pandas if missing
python3 -m pip show matplotlib > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Installing matplotlib and pandas..."
    python3 -m pip install --user matplotlib pandas
fi