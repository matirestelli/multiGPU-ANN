#!/bin/bash
#SBATCH -A IscrC_ANNS
#SBATCH -p boost_usr_prod
#SBATCH --qos boost_qos_dbg
#SBATCH --time 00:30:00      
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
cd ./experiments/Scenario_1/benchmarking-NNDescent-Deterministic-Cineca
cd build

##now commented for profiling
#decide: num of shards (here now 30) and num of vectors of the dataset (here now 1000000) (same number as the one used to created the dataset with create.py)
#compute-sanitizer --tool memcheck ./gknng false 3 10000 merge_only
./gknng false 12 100000 merge_only