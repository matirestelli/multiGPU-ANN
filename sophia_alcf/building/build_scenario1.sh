#!/bin/bash
source ../env_sophia.sh


cd $PROJECT_DIR/benchmarking-NNDescent

## build
mkdir -p build && cd build
cmake ..
make -j 8
