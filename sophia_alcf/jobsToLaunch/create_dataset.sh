#!/bin/bash
#PBS -A UIC-HPC
#PBS -q debug-scaling
#PBS -l select=1:ngpus=1
#PBS -l walltime=00:10:00
#PBS -l filesystems=home
#PBS -e create_dataset-%j.err
#PBS -o create_dataset-%j.out
#PBS -N create_dataset_20M_12d

# Use absolute path instead of relative
source $HOME/multiGPU-ANN/sophia_alcf/env_sophia.sh

# Limit OpenBLAS threads to avoid resource issues
export OPENBLAS_NUM_THREADS=1

cd $HOME/multiGPU-ANN/shared_data/artificial

# Create dataset: 20 million vectors, 12 dimensions
echo "Creating dataset: 20,000,000 vectors with 12 dimensions..."
python3 create.py 20000000 12

if [ $? -eq 0 ]; then
    echo "Dataset creation (SK_data.txt) completed successfully!"
    ls -lh SK_data.txt
    
    # Now convert to binary fvecs format using the benchmarking program
    echo "Converting to binary fvecs format..."
    cd $HOME/multiGPU-ANN/benchmarking-NNDescent/build
    ./gknng true
    
    if [ $? -eq 0 ]; then
        echo "Binary conversion completed successfully!"
        ls -lh $HOME/multiGPU-ANN/shared_data/vectors.fvecs
    else
        echo "Binary conversion failed!"
        exit 1
    fi
else
    echo "Dataset creation failed!"
    exit 1
fi
