#!/bin/bash
#PBS -A UIC-HPC
#PBS -q debug-scaling
#PBS -l select=1:ngpus=3
#PBS -l walltime=00:15:00
#PBS -l filesystems=home
#PBS -e pbs-%j.err
#PBS -o pbs-%j.out
#PBS -N nondet_normal

source $HOME/multiGPU-ANN/sophia_alcf/env_sophia.sh

## added to profile
export TMPDIR=/dev/shm
export CUDA_VISIBLE_DEVICES=0,1,2

cd $HOME/multiGPU-ANN/benchmarking-NNDescent/build

# START TIMER
START_TIME=$(date +%s)
echo "========================================="
echo "Starting NON-DETERMINISTIC HDD FULL execution (build + merge with HDD storage)"
echo "Starting execution at: $(date)"
echo "========================================="

# Run full pipeline: build shards + merge with HDD storage
# Parameters: true = use HDD, 9 = num_shards, 1000000 = num_vectors
./gknng false 6 20000000


# END TIMER
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
MINUTES=$((ELAPSED / 60))
SECONDS=$((ELAPSED % 60))

echo "========================================="
echo "Execution finished at: $(date)"
echo "Total time elapsed: ${MINUTES} minutes ${SECONDS} seconds"
echo "========================================="
