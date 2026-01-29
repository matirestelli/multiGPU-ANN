#!/bin/bash

PROJECT_DIR=$HOME/multiGPU-ANN

# SOPHIA at ALCF Module Setup (commented out - for reference)
# # CUDA is bundled with the TensorFlow conda environment
# # MPI and compilers are available as modules
# module purge
# module load conda/2024-08-08
# source /soft/applications/miniconda3/conda_tf/bin/activate
# module load compilers/openmpi/5.0.3

# POLARIS at ALCF Module Setup
# Note: POLARIS has modules pre-loaded, so we don't purge by default
# Uncomment 'module purge' only if needed to clean environment
# module purge

# Load NVIDIA Programming Environment (includes compilers and libraries)
module load PrgEnv-nvidia/8.6.0

# Load CUDA module
module load cuda/12.9

# Load Cray MPICH (standard MPI on Polaris - usually already loaded)
module load cray-mpich/9.0.1

# Override compilers to use plain gcc/g++ instead of MPI wrapper (code is single-process)
# This avoids linking against PGI OpenACC libraries
export CC=gcc
export CXX=g++
export MPICXX=mpicxx

# SOPHIA CUDA library paths (commented out - for reference)
# export CUDA_PATH=/soft/compilers/cudatoolkit/cuda-12.6.0
# export CUDA_cublas_LIBRARY=/soft/compilers/cudatoolkit/cuda-12.6.0/lib64/libcublas.so
# export CUDA_curand_LIBRARY=/soft/compilers/cudatoolkit/cuda-12.6.0/lib64/libcurand.so
# export CUDA_TOOLKIT_ROOT_DIR=/soft/compilers/cudatoolkit/cuda-12.6.0

# POLARIS CUDA library paths
export CUDA_PATH=$CUDA_HOME
export CUDA_TOOLKIT_ROOT_DIR=$CUDA_HOME
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH

# Verify CUDA is available
if command -v nvcc &> /dev/null; then
    echo "✓ CUDA toolkit loaded successfully"
    nvcc --version | head -1
else
    echo "⚠ Warning: nvcc not found. CUDA may not be properly configured."
fi

# Verify MPI is available
# SOPHIA: checks for mpiexec (OpenMPI)
# if command -v mpiexec &> /dev/null; then
#     echo "✓ OpenMPI loaded successfully"
# fi

# POLARIS: checks for mpiexec from Cray MPICH
if command -v mpiexec &> /dev/null; then
    echo "✓ Cray MPICH loaded successfully"
else
    echo "⚠ Warning: mpiexec not found. MPI may not be properly configured."
fi

# Install matplotlib & pandas if missing (for analysis scripts)
# Note: Network may be unavailable on compute nodes
python3 -m pip show matplotlib > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Installing matplotlib and pandas..."
    python3 -m pip install --user --no-cache-dir matplotlib pandas 2>/dev/null || echo "⚠ Note: Could not install matplotlib/pandas (network may be unavailable)"
fi

# POLARIS: Install cmake if missing (required for building)
python3 -m pip show cmake > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Installing cmake..."
    python3 -m pip install --user cmake 2>/dev/null || echo "⚠ Note: Could not install cmake"
fi

echo "Environment setup complete!"
