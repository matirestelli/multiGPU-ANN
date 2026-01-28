#!/bin/bash
#PBS -A UIC-HPC
#PBS -q by-gpu
#PBS -l select=1:ngpus=4
#PBS -l walltime=02:00:00
#PBS -l filesystems=home
#PBS -e pbs-%j.err
#PBS -o pbs-%j.out
#PBS -N nohdd_profile

source $HOME/multiGPU-ANN/sophia_alcf/env_sophia.sh

## added to profile
export TMPDIR=/dev/shm
export CUDA_VISIBLE_DEVICES=0,1,2

cd $HOME/multiGPU-ANN/benchmarking-NNDescent-NoHDD/build

# Create output directory for profiling traces
mkdir -p nsys-traces

# START TIMER
START_TIME=$(date +%s)
echo "========================================="
echo "Starting PROFILING NO-HDD execution with NVIDIA Nsight"
echo "Starting execution at: $(date)"
echo "========================================="

# Run with nsys profiling (PBS version - no srun needed)
nsys profile \
-o nsys-traces/nsys_output_${PBS_JOBID} \
--stats=true \
--cuda-memory-usage=true \
--trace=cuda,nvtx,osrt \
--force-overwrite=true \
--stop-on-exit=true \
./gknng false 3 1000000

# END TIMER
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
MINUTES=$((ELAPSED / 60))
SECONDS=$((ELAPSED % 60))

echo "========================================="
echo "Execution finished at: $(date)"
echo "Total time elapsed: ${MINUTES} minutes ${SECONDS} seconds"
echo "Profiling output saved to: nsys-traces/nsys_output_${PBS_JOBID}.nsys-rep"
echo "========================================="