*** Settings ***
Suite Setup                   Setup
Suite Teardown                Teardown
Test Teardown                 Test Teardown
Resource                      ${RENODEKEYWORDS}

*** Variables ***
${ADDRESS}                    0x2600000C
${VALUE}                      0xAB610000

*** Keywords ***
Create Machine
    Execute Command           i $ORIGIN/design.resc


*** Test Cases ***
Should Pass Validator Test

    Create Machine
    Create Log Tester         5000
    Start Emulation

    Wait For Log Entry        WriteDoubleWord to non existing peripheral at ${ADDRESS}, value ${VALUE}



