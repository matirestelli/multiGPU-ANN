# NNDescent Multi-GPU KNN Graph - Current Working Version

This README describes how to build, run, and test the **current version** of the NNDescent-Deterministic-No-HDD implementation. This is the baseline version being optimized for performance on the Leonardo supercomputer at Cineca.

## Project Overview

This implementation builds approximate k-nearest neighbor graphs using NNDescent algorithm with multi-GPU support. The current version:
- Uses 3 GPUs (configurable via `NUM_GPU` in source)
- Splits dataset into shards processed in parallel
- **Current optimization focus**: Fully in-memory pipeline (no disk I/O during build/merge)
- Target: Large-scale datasets with 12-dimensional vectors

## Prerequisites

- Access to Leonardo supercomputer (Cineca)
- Valid SLURM account with available budget (check with `saldo -b`)
- Python 3.11+ with scikit-learn, numpy, pandas, matplotlib
- NVHPC 24.5 with CUDA 12.4
- HPC-X MPI 2.19

## Complete Workflow

### Step 1: Create Dataset

Generate synthetic dataset with specified number of points (12 dimensions):

```bash
cd ~/hpps25-NNdescentNCCL/multigpu-ann/Scalable-distributed-algorithms-for-approximating-the-kNNG/experiments/Scenario_1/NNDescent-Deterministic-No-HDD/data/artificial

# Source environment to load Python modules
source ~/hpps25-NNdescentNCCL/multigpu-ann/env2.sh

# Create dataset (example: 1000 points)
python3 create.py 1000

# Verify creation
ls -lh SK_data.txt
head -5 SK_data.txt
```

**Files involved:**
- Input: `create.py` (dataset generator)
- Output: `data/artificial/SK_data.txt` (text format dataset)

---

### Step 2: Build the Project

Compile the CUDA/C++ code:

```bash
cd ~/hpps25-NNdescentNCCL/multigpu-ann

# Make build script executable (first time only)
chmod +x build_scenario1_NO-HDD.sh

# Build project
./build_scenario1_NO-HDD.sh
```

**Files involved:**
- Script: `build_scenario1_NO-HDD.sh` (build wrapper)
- Environment: `env2.sh` (loads modules and sets paths)
- Output: `experiments/Scenario_1/NNDescent-Deterministic-No-HDD/build/gknng` (binary executable)

**What happens:**
- Loads NVHPC/CUDA modules
- Creates build directory
- Runs CMake and Make
- Produces `gknng` executable

---

### Step 3: Convert Dataset to Binary Format

Convert text dataset to `.fvecs` binary format required by the algorithm:

```bash
cd ~/hpps25-NNdescentNCCL/multigpu-ann/Scalable-distributed-algorithms-for-approximating-the-kNNG/experiments/Scenario_1/NNDescent-Deterministic-No-HDD/build

# Run conversion (PREPARE mode)
./gknng true

# Verify output
ls -lh ../data/vectors.fvecs
```

**Files involved:**
- Input: `data/artificial/SK_data.txt`
- Output: `data/vectors.fvecs` (binary format)
- Source: `main.cu` (handles conversion when first argument is `true`)

---

### Step 4: Submit Job to Build and Merge KNN Graph

Submit SLURM job to run the full pipeline (build shards + merge):

```bash
cd ~/hpps25-NNdescentNCCL/multigpu-ann

# Make script executable (first time only)
chmod +x run_3gpu_NOHDD_fullTest.sh

# Submit job
sbatch run_3gpu_NOHDD_fullTest.sh
```

**Files involved:**
- Script: `run_3gpu_NOHDD_fullTest.sh` (SLURM job script)
- Binary: `build/gknng`
- Command executed: `./gknng false 3 1000 full`
  - `false` = don't prepare data (use existing .fvecs)
  - `3` = number of shards
  - `1000` = number of vectors in dataset
  - `full` = run full pipeline (build + merge)

**SLURM Configuration:**
- Account: `IscrC_ANNS` ⚠️ **Important:** Check your valid account with `saldo -b`
- Partition: `boost_usr_prod`
- QoS: `boost_qos_dbg` (debug queue, 15 min limit)
- Resources: 1 node, 3 GPUs, 100GB RAM
- Time limit: 15 minutes

**Note about SLURM Account:**
If you get "invalid account or expired budget" error:
```bash
# Check your available accounts
saldo -b

# Update the script with your active account name
# Edit line: #SBATCH -A YOUR_ACCOUNT_NAME
```

---

### Step 5: Monitor Job and Check Results

Monitor job execution:

```bash
# Check job status
squeue -u $USER

# Watch status in real-time (Ctrl+C to exit)
watch -n 2 'squeue -u $USER'

# Check output files when job completes
cd ~/hpps25-NNdescentNCCL/multigpu-ann
ls -ltr slurm-*.out slurm-*.err

# View output (replace JOBID with actual number)
tail -100 slurm-JOBID.out
tail -100 slurm-JOBID.err
```

Check results:

```bash
cd ~/hpps25-NNdescentNCCL/multigpu-ann/Scalable-distributed-algorithms-for-approximating-the-kNNG/experiments/Scenario_1/NNDescent-Deterministic-No-HDD

# Check output files
ls -lh results/
ls -lh data/

# View KNN graph results
head -20 results/NNDescent-KNNG.kgraph.txt
```

**Output Files:**
- `results/NNDescent-KNNG.kgraph` - Binary KNN graph
- `results/NNDescent-KNNG.kgraph.txt` - Text version (human-readable)
- `data/knn_local_saved.bin` - Backup of local-label graphs (from build phase)
- `data/knn_global_saved.bin` - Backup of global-label graphs (from build phase)
- `slurm-JOBID.out` - Standard output log
- `slurm-JOBID.err` - Error log

---

## Quick Reference: All Commands in Order

```bash
# 1. Create dataset
cd ~/hpps25-NNdescentNCCL/multigpu-ann/Scalable-distributed-algorithms-for-approximating-the-kNNG/experiments/Scenario_1/NNDescent-Deterministic-No-HDD/data/artificial
source ~/hpps25-NNdescentNCCL/multigpu-ann/env2.sh
python3 create.py 1000

# 2. Build project
cd ~/hpps25-NNdescentNCCL/multigpu-ann
chmod +x build_scenario1_NO-HDD.sh
./build_scenario1_NO-HDD.sh

# 3. Convert to binary
cd ~/hpps25-NNdescentNCCL/multigpu-ann/Scalable-distributed-algorithms-for-approximating-the-kNNG/experiments/Scenario_1/NNDescent-Deterministic-No-HDD/build
./gknng true

# 4. Submit job
cd ~/hpps25-NNdescentNCCL/multigpu-ann
chmod +x run_3gpu_NOHDD_fullTest.sh
sbatch run_3gpu_NOHDD_fullTest.sh

# 5. Monitor and check
squeue -u $USER
tail -50 slurm-*.out
```

---

## Key Files

| File | Purpose |
|------|---------|
| `env2.sh` | Environment setup (modules, paths) |
| `build_scenario1_NO-HDD.sh` | Build script |
| `run_3gpu_NOHDD_fullTest.sh` | SLURM job submission script |
| `create.py` | Dataset generator |
| `main.cu` | Main entry point |
| `gen_large_knngraph.cu` | Core algorithm implementation |
| `knndata_manager.hpp` | In-memory data manager |

---

## Configuration Parameters

### Dataset Size
Edit in `create.py` call:
```bash
python3 create.py <NUMBER_OF_POINTS>
```

### Number of Shards
Edit in `run_3gpu_NOHDD_fullTest.sh`:
```bash
srun ./gknng false <NUM_SHARDS> <NUM_POINTS> full
```

### Number of GPUs
Edit `NUM_GPU` in `gen_large_knngraph.cu`:
```cpp
#define NUM_GPU 3  // Change to desired number
```

### K (number of neighbors)
Edit `K_neighbors` in `main.cu`:
```cpp
#define K_neighbors 12  // Change to desired k
```

---

## Troubleshooting

### Build Errors
```bash
# Check CMake output
cat build/CMakeFiles/CMakeOutput.log

# Clean and rebuild
cd build && rm -rf * && cmake .. && make
```

### Job Submission Errors
```bash
# "invalid account or expired budget"
saldo -b  # Check valid accounts
# Update #SBATCH -A line in run_3gpu_NOHDD_fullTest.sh

# "Permission denied" on script
chmod +x run_3gpu_NOHDD_fullTest.sh
```

### Runtime Errors
- Check `slurm-JOBID.err` for CUDA errors
- With recent fixes, error messages will clearly indicate the problem
- Common issues:
  - Missing dataset: Run Step 1
  - Missing .fvecs: Run Step 3
  - Out of memory: Reduce dataset size or request more memory in job script

---

## Memory Requirements

For dataset with `n` points, `k=12` neighbors, 12 dimensions:

**Formula:** `n * 240 bytes` (single KNN copy) or `n * 432 bytes` (local + global copies)

**Examples (with safety factor 1.2):**
- 1,000 points: ~0.3 MB (trivial)
- 100,000 points: ~24 MB
- 1,000,000 points: ~240 MB
- 10,000,000 points: ~2.4 GB

Current job script requests 100 GB, sufficient for ~400 million points.

---

## Recent Optimizations Applied

This version includes critical safety fixes:
- ✅ CUDA error checking on all GPU operations
- ✅ Null pointer validation in data manager
- ✅ Proper memory cleanup with error checks
- ✅ Clear error messages for debugging

Old code preserved as comments (marked with `// OLD (no error check):`) for reference.

---

## Next Optimization Steps

Current bottlenecks being investigated:
1. Memory allocation patterns (NUMA awareness)
2. GPU kernel launch configurations
3. Host-device memory transfer optimization
4. Shard scheduling and load balancing

---

## Contact & Support

For Cineca-specific issues:
- Check Leonardo documentation: https://wiki.u-gov.it/confluence/display/SCAIUS/UG3.2%3A+LEONARDO+UserGuide
- Contact Cineca support: superc@cineca.it

For code/algorithm questions:
- Check project repository issues
- Review inline comments in source files
