# Renode MPW tester

Copyright (c) 2022 [Antmicro](https://www.antmicro.com)

This repo is aimed to be a template tester for SkyWater MPW designs.
It uses [Renode](https://renode.io), Antmicro's open source simulation framework, to run tests with the Management Area of the design simulated by Renode and the user area simulated via Verilator.

We use https://github.com/Askartos/fossiAES/ design as a sample, but other digital designs can be tested as well, after minor changes.

The testing flow is executed by [GitHub Actions workflow](.github/workflows).

To adapt this flow to your own design, change the following:

* ``TEST_NAME`` and ``DESIGN_NAME`` variables in the [GitHub workflow](.github/workflows/build_and_test.yml)
*  VTOP file name in [verilator/CMakeList.txt](verilator/CMakeLists.txt) (currently ``aes.v``)
* name of the generated TOP class (currently ``Vaes``) and path to a generated header (currently ``Vaes.h``) in [Verilator connection shim layer](verilator/sim_main.cpp)

This repository is still work in progress.
