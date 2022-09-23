# Renode MPW tester

Copyright (c) 2022 [Antmicro](https://www.antmicro.com)

This repo is a template for testing SkyWater MPW designs using [Renode](https://renode.io), Antmicro's open source simulation framework, in a co-simulation setup with [Verilator](https://github.com/verilator/verilator).

The setup allows MPW participants to test their HDL by running real software and tests, with the Management Area of the design simulated by Renode and the user area simulated via Verilator.

The [FossiAES](https://github.com/Askartos/fossiAES/) design [submitted to MPW 6](https://platform.efabless.com/projects/1067) is used as a sample, but this template should be easy to adapt to other digital designs using the new Caravel harness, after minor changes.

The testing flow is executed by [GitHub Actions workflow](.github/workflows).

To adapt this flow to your own design, set TEST_NAME and DESIGN_NAME, VTOP file (-f flag), CLASS and INCLUDE names of generated TOP class

```
./build.sh [-v DESIGN_NAME ] [-t TEST_NAME] [-i FILE] [-I INCLUDE] [-c CLASS] [-TV] [MODE]

 -v DESIGN_NAME   - Set design to use, default is aes
 -t TEST_NAME     - Set test name to use, default is aes_test
 -f FILE          - Set specific verilator file to use
 -i FILE          - Copy additional file to verilator
 -I INCLUDE       - Set include in sim_main.cpp, default is Vaes.h
 -C CLASS         - Set top class in sim_main.cpp, default is Vaes
 -V               - Display all possible design names
 -T               - Display all possible test names
 MODE             - Function to run, default is ALL
      soc_configuration       - Build soc configuration
      renode_configuration    - Build renode configuration
      test                    - Build test
      verilate_design         - Verilate design
      ALL                     - Run all functions above
```

To build all things run:
```
./prepare.sh # Run this only once
./build.sh
./test.sh
```

This repository is still work in progress.
