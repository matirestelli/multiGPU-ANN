#!/bin/bash
source ../env_sophia.sh


cd $PROJECT_DIR/benchmarking-NNDescent-Deterministic-NoHDD

## Clean old build artifacts
rm -rf build

## build
mkdir -p build && cd build
cmake ..
make -j 8
