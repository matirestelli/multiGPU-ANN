#!/bin/bash
#PBS -A UIC-HPC
#PBS -q debug-scaling
#PBS -l select=1:ngpus=3
#PBS -l walltime=00:45:00
#PBS -l filesystems=home
#PBS -e pbs-%j.err
#PBS -o pbs-%j.out
#PBS -N profile_small_dataset

source $HOME/multiGPU-ANN/sophia_alcf/env_sophia.sh

## Profiling environment setup
export TMPDIR=/dev/shm
export CUDA_VISIBLE_DEVICES=0,1,2

# Path to nsys
NSYS=/opt/nvidia/hpc_sdk/Linux_x86_64/25.5/compilers/bin/nsys

cd $HOME/multiGPU-ANN/benchmarking-NNDescent-NoHDD/build

# START TIMER
START_TIME=$(date +%s)
echo "========================================="
echo "Starting Nsight Systems Profiling (smallest dataset)"
echo "Profile: NON-DETERMINISTIC HDD FULL execution"
echo "Dataset: 1000000 vectors, k=32, 3 shards"
echo "Starting execution at: $(date)"
echo "========================================="

# Run with Nsight Systems profiling
# --trace=cuda,nvtx: Capture CUDA API calls and NVTX markers
# --output: Output file name with job ID for uniqueness
$NSYS profile \
  --trace=cuda,nvtx \
  --output=/home/mrest/multiGPU-ANN/sophia_alcf/jobsToLaunch/profile_%j \
  --force-overwrite=true \
  ./gknng false 3 1000000

# END TIMER
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
MINUTES=$((ELAPSED / 60))
SECONDS=$((ELAPSED % 60))

echo "========================================="
echo "Execution finished at: $(date)"
echo "Total time elapsed: ${MINUTES} minutes ${SECONDS} seconds"
echo "========================================="
echo "Profile output: /home/mrest/multiGPU-ANN/sophia_alcf/jobsToLaunch/profile_${PBS_JOBID}.nsys-rep"
echo ""
echo "To analyze the profile:"
echo "1. Download the file: scp your_user@sophia.alcf.anl.gov:/home/mrest/multiGPU-ANN/sophia_alcf/jobsToLaunch/profile_*.nsys-rep ."
echo "2. Open in Nsight Systems GUI on your local machine"
echo "========================================="
