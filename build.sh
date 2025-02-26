#!/bin/sh

# for rootless
make package FINALPACKAGE=1 ROOTLESS=1

# for rootful
# make package FINALPACKAGE=1