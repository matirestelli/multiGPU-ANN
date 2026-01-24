#!/bin/bash
source env2.sh


cd $PROJECT_DIR/Scalable-distributed-algorithms-for-approximating-the-kNNG
cd ./experiments/Scenario_1/benchmarking-NNDescent-IO/


## build
mkdir -p build && cd build
cmake ..
make -j 8
