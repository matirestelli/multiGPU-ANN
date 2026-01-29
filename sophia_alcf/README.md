# Sophia at ALCF - PBS Scripts

This folder contains converted scripts from SLURM (Leonardo) to PBS (Sophia at ALCF).

## Key Changes Made

### SLURM → PBS Conversion

1. **Job Directives**: `#SBATCH` → `#PBS`
   - `#SBATCH -A IscrC_ANNS` → `#PBS -A <account_name>` (needs customization)
   - `#SBATCH -p boost_usr_prod` → `#PBS -l place=scatter` (PBS resource selection)
   - `#SBATCH -N 1 --gres=gpu:3` → `#PBS -l select=1:ngpus=3`
   - `#SBATCH --time 02:00:00` → `#PBS -l walltime=02:00:00`
   - `#SBATCH --mem=100000` → removed (handled by PBS select statement)
   - Output files: `slurm-%j.err/out` → `pbs-%j.err/out`

2. **MPI Launcher**: `srun` → `mpiexec`
   - `srun ./gknng ...` → `mpiexec -n 3 ./gknng ...`

3. **Environment**: Changed from `env2.sh` → `env_sophia.sh`

## Configuration Required

### 1. ✅ Module Setup (SOLVED!)
**Good news:** CUDA is bundled with Sophia's TensorFlow conda environment. The `env_sophia.sh` file is now configured to:
- Load `conda/2024-08-08`
- Activate `/soft/applications/miniconda3/conda_tf/` (includes CUDA 12.3+)
- Load `compilers/openmpi/5.0.3` for MPI

The environment setup script automatically verifies that CUDA and MPI are loaded.

### 2. Account Name
Update `<account_name>` in all job scripts with your Sophia allocation:
```bash
#PBS -A your_account_name
```

### 3. Project Directory
The `PROJECT_DIR` is set to `$HOME/multiGPU-ANN`. Adjust in env_sophia.sh if needed.

## Environment Details

**Available on Sophia:**
- **CUDA**: Included in `/soft/applications/miniconda3/conda_tf/` (CUDA 12.3+)
- **MPI**: `compilers/openmpi/5.0.3`
- **Conda**: `conda/2024-08-08`
- **Python**: Available via conda environment

**No longer needed:**
- ~~cudatoolkit module~~ (bundled with TensorFlow env)
- ~~cray-mpich~~ (OpenMPI available instead)
- ~~separate python module~~ (available via conda)

## Folder Structure

```
sophia_alcf/
├── env_sophia.sh                                    # Environment setup (NEEDS MODULE CUSTOMIZATION)
├── building/                                        # Build scripts
│   ├── build_scenario1_deterministic.sh
│   ├── build_scenario1_IO.sh
│   ├── build_scenario1_NO-HDD.sh
│   ├── build_scenario1_nonDet-NO-HDD.sh
│   └── build_scenario1_nonDet.sh
└── jobsToLaunch/                                    # PBS job submission scripts
    ├── run_3gpu_deterministic_normal.sh
    ├── run_3gpu_deterministic_build_only.sh
    ├── run_3gpu_deterministic_create_vectors_dataset.sh
    ├── run_3gpu_deterministic_merge_only.sh
    ├── run_3gpu_deterministic_generate_dummy_knn.sh
    ├── run_3gpu_IO_create_vectors.sh
    ├── run_3gpu_NO_HDD_merge_only.sh
    ├── run_3gpu_NOHDD_PROFILE.sh
    ├── run_3gpu_nonDet_NO_HDD_full.sh
    └── run_3gpu_nonDet.sh
```

## Usage

1. **Update env_sophia.sh** with Sophia's actual module names
2. **Update account name** in all PBS scripts (replace `<account_name>`)
3. **Make scripts executable**:
   ```bash
   chmod +x env_sophia.sh
   chmod +x building/*.sh
   chmod +x jobsToLaunch/*.sh
   ```
4. **Copy to Sophia** and adjust as needed
5. **Submit jobs**:
   ```bash
   qsub jobsToLaunch/run_3gpu_deterministic_normal.sh
   qsub jobsToLaunch/run_3gpu_nonDet.sh
   # etc.
   ```

## PBS vs SLURM Cheat Sheet

| Task | SLURM | PBS |
|------|-------|-----|
| Job name | `#SBATCH --job-name=` | `#PBS -N` |
| Account | `#SBATCH -A` | `#PBS -A` |
| GPUs | `#SBATCH --gres=gpu:3` | `#PBS -l select=1:ngpus=3` |
| Time | `#SBATCH --time 02:00:00` | `#PBS -l walltime=02:00:00` |
| Memory | `#SBATCH --mem=100000` | (handled in select) |
| Output | `#SBATCH -o file.out` | `#PBS -o file.out` |
| Error | `#SBATCH -e file.err` | `#PBS -e file.err` |
| MPI Launch | `srun` | `mpiexec` or `aprun` |
| Job Submit | `sbatch` | `qsub` |

## Next Steps

1. Connect to Sophia and check available modules
2. Update env_sophia.sh with actual module names
3. Set your ALCF account code
4. Copy scripts to Sophia and test with a small job first
