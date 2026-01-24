#!/bin/bash
#SBATCH -A IscrC_GrOUT
#SBATCH -p boost_usr_prod
#SBATCH --qos boost_qos_dbg
#SBATCH --time 00:15:00      
#SBATCH -N 1                 
#SBATCH --ntasks-per-node=3  
#SBATCH --gres=gpu:3           
#SBATCH --mem=100000            
#SBATCH -e slurm-%j.err         # error files
#SBATCH -o slurm-%j.out         # output files
#SBATCH --job-name=test

source env2.sh

## added to profile
export TMPDIR=/dev/shm

cd $PROJECT_DIR/Scalable-distributed-algorithms-for-approximating-the-kNNG
cd ./experiments/Scenario_1/benchmarking-NNDescent-Deterministic
cd build

##now commented for profiling
#decide: num of shards (here now 2) and num of vectors of the dataset 
#(here now 1024) (same number as the one used to created the dataset with 
#create.py) and k neigherst neighbors(here 12)
srun  ./generate_dummy_knn 1024 12 3