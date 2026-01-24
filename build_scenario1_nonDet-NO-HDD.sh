#!/bin/bash
source env2.sh


cd $PROJECT_DIR/Scalable-distributed-algorithms-for-approximating-the-kNNG
cd ./experiments/Scenario_1/NNDescent-No-HDD/

## build
mkdir -p build && cd build
cmake ..
make
