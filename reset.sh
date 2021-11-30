#!/bin/bash

#====================================================#
############ Cleanup prior runs    ###################
#====================================================#
mkdir raw
cp tmp/raw*.xml raw/

rm -rf tmp/*
rm -rf results/*

mkdir -p tmp
mkdir -p results

cp raw/raw*.xml tmp/
rm -rf raw/
