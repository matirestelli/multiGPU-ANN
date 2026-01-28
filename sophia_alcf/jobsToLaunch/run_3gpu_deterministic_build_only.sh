#!/bin/bash -l
#PBS -A UIC-HPC
#PBS -q by-gpu
#PBS -l select=1:ngpus=4
#PBS -l walltime=02:00:00
#PBS -l filesystems=home
#PBS -e pbs-%j.err
#PBS -o pbs-%j.out
#PBS -N test_deterministic
#PBS -N lstm_oktopk_debug
#PBS -o logs/lstm_oktopk_debug${PBS_JOBID}.out
#PBS -e logs/lstm_oktopk_debug${PBS_JOBID}.err

source $HOME/multiGPU-ANN/sophia_alcf/env_sophia.sh

## added to profile
export TMPDIR=/dev/shm
export CUDA_VISIBLE_DEVICES=0,1,2

cd $HOME/multiGPU-ANN/benchmarking-NNDescent-Deterministic/build

# START TIMER
START_TIME=$(date +%s)
echo "========================================="
echo "Starting execution at: $(date)"
echo "========================================="

##now commented for profiling
#decide: num of shards (here now 12) and num of vectors of the dataset (here now 1000000)
./gknng false 12 1000000 merge_only


# END TIMER
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
MINUTES=$((ELAPSED / 60))
SECONDS=$((ELAPSED % 60))

echo "========================================="
echo "Execution finished at: $(date)"
echo "Total time elapsed: ${MINUTES} minutes ${SECONDS} seconds"
echo "========================================="
