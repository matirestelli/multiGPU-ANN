#!/bin/bash
#SBATCH -A IscrC_ANNS
#SBATCH -p boost_usr_prod
#SBATCH --time 02:00:00      
#SBATCH -N 1                        
#SBATCH --mem=100000    
#SBATCH --gres=gpu:3        
#SBATCH -e slurm-%j.err         # error files
#SBATCH -o slurm-%j.out         # output files
#SBATCH --job-name=nonDet_NoHDD_full

source env2.sh

## added to profile
export TMPDIR=/dev/shm

cd $PROJECT_DIR/Scalable-distributed-algorithms-for-approximating-the-kNNG
cd ./experiments/Scenario_1/NNDescent-No-HDD
cd build

# START TIMER
START_TIME=$(date +%s)
echo "========================================="
echo "Starting NON-DETERMINISTIC No-HDD FULL execution (build + merge in memory)"
echo "Starting execution at: $(date)"
echo "Dataset: SIFT-1M (1,000,000 vectors, D=128, K=32)"
echo "Shards: 3 (matching 3 GPUs)"
echo "========================================="

# Run full pipeline: build shards + merge in memory (no HDD intermediate storage)
# Parameters: false = skip TXT->FVEC conversion, 3 = num_shards, 1000000 = num_vectors, full = mode
srun ./gknng false 3 1000000 full

# END TIMER
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
MINUTES=$((ELAPSED / 60))
SECONDS=$((ELAPSED % 60))

echo "========================================="
echo "Execution finished at: $(date)"
echo "Total time elapsed: ${MINUTES} minutes ${SECONDS} seconds"
echo "========================================="
