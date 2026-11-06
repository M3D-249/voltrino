Just learning how to program ATMega328p (intro to embedded systems) directly without using Arduino IDE or library, understading how to communicate with a microcontroller, how to use registers, etc, while doing all that in simple plain C language.

by the completion of this repo I should have a complete framework to build and deploy firmware to AVR family microcontrollers, and good understanding of how all that works.

## Tools Used
1. arv-gcc: to compile code for AVR controllers (ATMega328p in my case)
2. arv-dude: to program the micro-controller on the Arduino board (Arduino Uno in my case)

## Build and Deployment
there are two scripts `build.sh` and `build.bat` for building, deploying and inspecting the project  