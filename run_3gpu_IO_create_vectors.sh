#!/bin/bash
#SBATCH -A IscrC_GrOUT
#SBATCH -p boost_usr_prod
#SBATCH --qos boost_qos_dbg
#SBATCH --time 00:15:00      
#SBATCH -N 1                 
#SBATCH --gres=gpu:3           
#SBATCH --mem=100000            
#SBATCH -e slurm-%j.err         # error files
#SBATCH -o slurm-%j.out         # output files
#SBATCH --job-name=test

source env2.sh

## added to profile
export TMPDIR=/dev/shm

cd $PROJECT_DIR/Scalable-distributed-algorithms-for-approximating-the-kNNG
cd ./experiments/Scenario_1/benchmarking-NNDescent-IO/
cd build

##now commented for profiling
#srun gknng
./gknng true 9 1000000