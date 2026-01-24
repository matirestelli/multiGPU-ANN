#!/bin/bash
#SBATCH -A IscrC_ANNS
#SBATCH -p boost_usr_prod

#SBATCH --time 02:00:00      
#SBATCH -N 1                        
#SBATCH --mem=100000    
#SBATCH --gres=gpu:3        
#SBATCH -e slurm-%j.err         # error files
#SBATCH -o slurm-%j.out         # output files
#SBATCH --job-name=test_deterministic

source env2.sh

## added to profile
export TMPDIR=/dev/shm

cd $PROJECT_DIR/Scalable-distributed-algorithms-for-approximating-the-kNNG
cd ./experiments/Scenario_1/NNDescent-Deterministic-No-HDD
cd build

# START TIMER
START_TIME=$(date +%s)
echo "========================================="
echo "Starting execution at: $(date)"
echo "========================================="

##now commented for profiling
#decide: num of shards (here now 30) and num of vectors of the dataset (here now 1000000) (same number as the one used to created the dataset with create.py)
srun ./gknng false 12 1000000 merge_only

# END TIMER
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
MINUTES=$((ELAPSED / 60))
SECONDS=$((ELAPSED % 60))

echo "========================================="
echo "Execution finished at: $(date)"
echo "Total time elapsed: ${MINUTES} minutes ${SECONDS} seconds"
echo "========================================="