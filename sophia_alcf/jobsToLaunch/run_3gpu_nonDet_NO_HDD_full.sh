#!/bin/bash
#PBS -A UIC-HPC
#PBS -q debug-scaling
#PBS -l select=1:ngpus=3
#PBS -l walltime=00:25:00
#PBS -l filesystems=home
#PBS -e pbs-%j.err
#PBS -o pbs-%j.out
#PBS -N nondet_nohdd_fulls

# Use absolute path instead of relative
source $HOME/multiGPU-ANN/sophia_alcf/env_sophia.sh

## added to profile
export TMPDIR=/dev/shm
export CUDA_VISIBLE_DEVICES=0,1,2

cd $HOME/multiGPU-ANN/benchmarking-NNDescent-NoHDD/build

# START TIMER
START_TIME=$(date +%s)
echo "========================================="
echo "Starting NON-DETERMINISTIC NO-HDD FULL execution (build + merge in memory)"
echo "Starting execution at: $(date)"
echo "========================================="

# Run full pipeline: build shards + merge in memory (no HDD intermediate storage)
# Parameters: false = skip TXT->FVEC conversion, 3 = num_shards, 1000000 = num_vectors, full = mode
./gknng false 3 30000000 full


# END TIMER
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
MINUTES=$((ELAPSED / 60))
SECONDS=$((ELAPSED % 60))

echo "========================================="
echo "Execution finished at: $(date)"
echo "Total time elapsed: ${MINUTES} minutes ${SECONDS} seconds"
echo "========================================="
