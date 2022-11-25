# Renode MPW tester

Copyright (c) 2022 [Antmicro](https://www.antmicro.com)

This repo is a template for testing SkyWater MPW designs using [Renode](https://renode.io), Antmicro's open source simulation framework, in a co-simulation setup with [Verilator](https://github.com/verilator/verilator).

The setup allows MPW participants to test their HDL by running real software and tests, with the Management Area of the design simulated by Renode and the user area simulated via Verilator.

The [FossiAES](https://github.com/Askartos/fossiAES/) design [submitted to MPW 6](https://platform.efabless.com/projects/1067) is used as a sample, but this template should be easy to adapt to other digital designs using the new Caravel harness, after minor changes.

The testing flow is executed by [GitHub Actions workflow](.github/workflows).

To reproduce the flow locally, first run:
```
./prepare.sh
```

This will download a pre-built toolchain, apply necessary patches to the design repository and create an output directory for artifacts.
Running the prepare script once after cloning the repository is enough - there is no need to call it before every build.

Now run:

```
./build.sh
./test.sh
```

To use a custom design, set TEST_NAME, DESIGN_NAME, VTOP, CLASS and INCLUDE parameters when calling the build script:

```
./build.sh [-v DESIGN_NAME ] [-t TEST_NAME] [-i FILE] [-I INCLUDE] [-c CLASS] [-TV] [MODE]

 -v DESIGN_NAME   - Set design to use, default is aes
 -t TEST_NAME     - Set test name to use, default is aes_test
 -f MAIN_FILE     - Set specific verilator file to use
 -i EXTRA_FILE    - Copy additional file to verilator
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

This repository is still work in progress.
