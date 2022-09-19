# Renode MPW tester

Copyright (c) 2022 [Antmicro](https://www.antmicro.com)

This repo is a template for testing SkyWater MPW designs using [Renode](https://renode.io), Antmicro's open source simulation framework, in a co-simulation setup with [Verilator](https://github.com/verilator/verilator).

The setup allows MPW participants to test their HDL by running real software and tests, with the Management Area of the design simulated by Renode and the user area simulated via Verilator.

The [FossiAES](https://github.com/Askartos/fossiAES/) design [submitted to MPW 6](https://platform.efabless.com/projects/1067) is used as a sample, but this template should be easy to adapt to other digital designs using the new Caravel harness, after minor changes.

The testing flow is executed by [GitHub Actions workflow](.github/workflows).

To adapt this flow to your own design, change the following:

* ``TEST_NAME`` and ``DESIGN_NAME`` variables in the [GitHub workflow](.github/workflows/build_and_test.yml)
*  VTOP file name in [verilator/CMakeList.txt](verilator/CMakeLists.txt) (currently ``aes.v``)
* name of the generated TOP class (currently ``Vaes``) and path to a generated header (currently ``Vaes.h``) in the [Verilator connection shim layer](verilator/sim_main.cpp)

This repository is still work in progress.
