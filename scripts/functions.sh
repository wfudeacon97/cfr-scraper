#!/bin/bash

# $1 is the chapter number for title 48
function getNameForChapter(){
  if [  -f agencies/agency-chapter-${1}.json ] ; then
    agencyName=$(cat agencies/agency-chapter-${1}.json | jq '.[0]' | jq '.shortName' -r)
    agencyDisplayname=$(echo ${agencyName} | tr [:lower:] [:upper:])
    agencyId=$(cat agencies/agency-chapter-${1}.json | jq '.[0]' | jq '.agencyId' -r)
  else
    agencyName=$1
  fi
}

resultsDir=results/
scriptsDir="./scripts/"
tmpDir="tmp/"
connectDir=connect/

enableAdSense="Y"
enableAdSenseSuppl="Y"
