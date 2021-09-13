#!/bin/bash

# $1 is the chapter number for title 48
function getNameForChapter(){
  if [ "$1" == "4" ] ; then
    agencyName=agg
    agencyId=0
  elif [ "$1" == "8" ] ; then
    agencyName=vaar
    agencyId=520
  else
    agencyName=$1
  fi
}
