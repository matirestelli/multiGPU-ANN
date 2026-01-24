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
#SBATCH --job-name=profile

source env2.sh
export TMPDIR=/dev/shm

cd $PROJECT_DIR/Scalable-distributed-algorithms-for-approximating-the-kNNG
cd ./experiments/Scenario_1/NNDescent-Deterministic-No-HDD
cd build

mkdir -p nsys-traces

srun \
  nsys profile \
  -o nsys-traces/nsys_output_%q{SLURM_PROCID} \
  --stats=true \
  --cuda-memory-usage=true \
  --trace=cuda,nvtx,osrt \
  --force-overwrite=true \
  --stop-on-exit=true \
  ./gknng false 3 1000 full 

#srun ./gknng false 3 1000 full 