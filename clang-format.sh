#!/bin/bash

PATH=~/.bin:~/bin:$PATH
export PATH

clang-format -i **/**/*.h **/**/*.m
