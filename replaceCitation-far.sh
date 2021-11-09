source scripts/functions.sh

ch=1
getNameForChapter ${ch}

scriptFile=tmp/replace-${agencyName}.sh
echo "" > ${scriptFile}

while read i; do
  echo "# ($i)" >> ${scriptFile}
  filename=""
  filename=$(cut -d: -f1 <<< "$i")
  if [ "${filename}" != "${i}" ] ; then
    txt=${i/${filename}:/}
    part=${txt:12}

    echo "#A. Replacing ${txt} in file ${filename}" >> ${scriptFile}
    echo "sed -i '' \"s|$txt|<a href=\\\"48.${ch}.$part.html\\\">$txt</a>|gI\" ${filename}" >> ${scriptFile}
  else
    echo "#A. NO FILENAME" >> ${scriptFile}
  fi
  echo "" >> ${scriptFile}
done < <(grep -iro --color=never "\b48 CFR PART [0-9][0-9]\b" html/${agencyName}/*.html  | sort | uniq )

while read i; do
  echo "# ($i)" >> ${scriptFile}
  filename=""
  filename=$(cut -d: -f1 <<< "$i")
  if [ "${filename}" != "${i}" ] ; then
    txt=${i/${filename}:/}
    fullSection=${txt:4}

    part=$(cut -d. -f1 <<< "$fullSection")

    section=$(cut -d. -f2 <<< "$fullSection")
    if [ "${#section}" == "3" ] ; then
      subpart=${section:0:1}
    elif [ "${#section}" == "4" ] ; then
      subpart=${section:0:2}
    else
      subpart=0
    fi
    echo "#B. ${txt} : fullSection: ${fullSection}, part: ${part}, subpart: ${subpart}" >> ${scriptFile}
    echo "#B. Replacing ${txt} in file ${filename}" >> ${scriptFile}
    echo "sed -i '' \"s|$txt|<a href=\\\"48.${ch}.${part}.${subpart}.html#48.${ch}.${fullSection}\\\">$txt</a>|gI\" ${filename}" >> ${scriptFile}
  else
    echo "#B. NO FILENAME" >> ${scriptFile}
  fi
  echo "" >> ${scriptFile}
done < <(grep -iro --color=never "\bFAR [0-9]*\.[0-9]*\b" html/${agencyName}/*.html | sort | uniq )

while read i; do
  echo "# ($i)" >> ${scriptFile}
  filename=""
  #test=$(grep -i "[0-9]*.[0-9]*([a-z]*)" <<< $i)
  #if [ "$test" == "" ] ; then
  filename=$(cut -d: -f1 <<< "$i")
  if [ "${filename}" != "${i}" ] ; then
    txt=${i/${filename}:/}
    fullSection=${txt/(see /}
    fullSection=${fullSection/)/}

    part=$(cut -d. -f1 <<< "$fullSection")
    section=$(cut -d. -f2 <<< "$fullSection")
    if [ "${#section}" == "3" ] ; then
      subpart=${section:0:1}
    elif [ "${#section}" == "4" ] ; then
      subpart=${section:0:2}
    else
      subpart=0
    fi

    echo "#C. ${txt} : fullSection: ${fullSection}, part: ${part}, subpart: ${subpart}" >> ${scriptFile}
    echo "#C. Replacing ${txt} in file ${filename}" >> ${scriptFile}
    echo "sed -i '' \"s|$txt|<a href=\\\"48.${ch}.${part}.${subpart}.html#48.${ch}.${fullSection}\\\">$txt</a>|gI\" ${filename}" >> ${scriptFile}
  else
    echo "#C. NO FILENAME" >> ${scriptFile}
  fi
  echo "" >> ${scriptFile}
  #fi
done < <(grep -iro --color=never "(see [0-9]*\.[0-9]*)" html/${agencyName}/*.html | sort | uniq  )

while read i; do
  echo "# ($i)" >> ${scriptFile}
  filename=""
  #test=$(grep -i "[0-9]*.[0-9]*([a-z]*)([0-9]*)" <<< $i)
  #if [ "$test" == "" ] ; then
  filename=$(cut -d: -f1 <<< "$i")
  if [ "${filename}" != "${i}" ] ; then
    txt=${i/${filename}:/}
    fullSection=${txt/(see /}

    fullSection=$(cut -d'(' -f1 <<< "$fullSection")

    part=$(cut -d. -f1 <<< "$fullSection")
    section=$(cut -d. -f2 <<< "$fullSection")
    if [ "${#section}" == "3" ] ; then
      subpart=${section:0:1}
    elif [ "${#section}" == "4" ] ; then
      subpart=${section:0:2}
    else
      subpart=0
    fi

    echo "#D. ${txt} : fullSection: ${fullSection}, part: ${part}, subpart: ${subpart}" >> ${scriptFile}
    echo "#D. Replacing ${txt} in file ${filename}" >> ${scriptFile}
    echo "sed -i '' \"s|$txt|<a href=\\\"48.${ch}.${part}.${subpart}.html#48.${ch}.${fullSection}\\\">$txt</a>|gI\" ${filename}" >> ${scriptFile}
  else
    echo "#D. NO FILENAME" >> ${scriptFile}
  fi
  echo "" >> ${scriptFile}
  #fi
done < <(grep -iro --color=never "(see [0-9]*\.[0-9]*([a-z]*))" html/${agencyName}/*.html | sort | uniq)

while read i; do
  echo "# ($i)" >> ${scriptFile}
  filename=""
  filename=$(cut -d: -f1 <<< "$i")
  if [ "${filename}" != "${i}" ] ; then
    txt=${i/${filename}:/}
    fullSection=${txt/(see /}

    fullSection=$(cut -d'(' -f1 <<< "$fullSection")

    part=$(cut -d. -f1 <<< "$fullSection")
    section=$(cut -d. -f2 <<< "$fullSection")
    if [ "${#section}" == "3" ] ; then
      subpart=${section:0:1}
    elif [ "${#section}" == "4" ] ; then
      subpart=${section:0:2}
    else
      subpart=0
    fi

    echo "#E. ${txt} : fullSection: ${fullSection}, part: ${part}, subpart: ${subpart}" >> ${scriptFile}
    echo "#E. Replacing ${txt} in file ${filename}" >> ${scriptFile}
    echo "sed -i '' \"s|$txt|<a href=\\\"48.${ch}.${part}.${subpart}.html#48.${ch}.${fullSection}\\\">$txt</a>|gI\" ${filename}" >> ${scriptFile}
  else
    echo "#E. NO FILENAME" >> ${scriptFile}
  fi
  echo "" >> ${scriptFile}
done < <(grep -iro --color=never "(see [0-9]*\.[0-9]*([a-z]*)([0-9]*))" html/${agencyName}/*.html | sort | uniq )

#25.502(a)  (example in 25.504-1)
#  TODO:  This could be a subset of D or E
#while read i; do
#  echo "# ($i)" >> ${scriptFile}
#  filename=""
#  filename=$(cut -d: -f1 <<< "$i")
#  if [ "${filename}" != "${i}" ] ; then
#    txt=${i/${filename}:/}
#
#    fullSection=$(cut -d'(' -f1 <<< "$fullSection")
#
#    part=$(cut -d. -f1 <<< "$fullSection")
#    section=$(cut -d. -f2 <<< "$fullSection")
#    if [ "${#section}" == "3" ] ; then
#      subpart=${section:0:1}
#    else
#      subpart=0
#    fi
#
#    echo "#F. ${txt} : fullSection: ${fullSection}, part: ${part}, subpart: ${subpart}" >> ${scriptFile}
#    echo "#F. Replacing ${txt} in file ${filename}" >> ${scriptFile}
#    echo "sed -i '' \"s|$txt|<a href=\\\"48.${ch}.${part}.${subpart}.html#48.${ch}.${fullSection}\\\">$txt</a>|gI\" ${filename}" >> ${scriptFile}
#  else
#    echo "#F. NO FILENAME" >> ${scriptFile}
#  fi
#  echo "" >> ${scriptFile}
#done < <(grep -iro --color=never "[0-9]*\.[0-9]*([a-z]*)" html/${agencyName}/*.html | sort | uniq )

#(see 15.101-1) (example in 15.305)
while read i; do
  echo "# ($i)" >> ${scriptFile}
  filename=""
  filename=$(cut -d: -f1 <<< "$i")
  if [ "${filename}" != "${i}" ] ; then
    txt=${i/${filename}:/}
    fullSection=${txt:4}
    fullSection=$(cut -d- -f1 <<< "$fullSection")

    part=$(cut -d. -f1 <<< "$fullSection")

    section=$(cut -d. -f2 <<< "$fullSection")
    if [ "${#section}" == "3" ] ; then
      subpart=${section:0:1}
    elif [ "${#section}" == "4" ] ; then
      subpart=${section:0:2}
    else
      subpart=0
    fi
    echo "#G. ${txt} : fullSection: ${fullSection}, part: ${part}, subpart: ${subpart}" >> ${scriptFile}
    echo "#G. Replacing ${txt} in file ${filename}" >> ${scriptFile}
    echo "sed -i '' \"s|$txt|<a href=\\\"48.${ch}.${part}.${subpart}.html#48.${ch}.${fullSection}\\\">$txt</a>|gI\" ${filename}" >> ${scriptFile}
  else
    echo "#G. NO FILENAME" >> ${scriptFile}
  fi
  echo "" >> ${scriptFile}
done < <(grep -iro --color=never "\bFAR [0-9]*\.[0-9]*-[0-9]*\b " html/${agencyName}/*.html | sort | uniq )

#(see Subpart 25.4)
while read i; do
  echo "# ($i)" >> ${scriptFile}
  filename=""
  filename=$(cut -d: -f1 <<< "$i")
  if [ "${filename}" != "${i}" ] ; then
    txt=${i/${filename}:/}
    fullSection=${txt:13}
    fullSection=${fullSection/)/}
    fullSection=$(cut -d- -f1 <<< "$fullSection")

    echo "#H. ${txt} : fullSection: ${fullSection}" >> ${scriptFile}
    echo "#H. Replacing ${txt} in file ${filename}" >> ${scriptFile}
    echo "sed -i '' \"s|$txt|<a href=\\\"48.${ch}.${fullSection}.html\\\">$txt</a>|gI\" ${filename}" >> ${scriptFile}
  else
    echo "#H. NO FILENAME" >> ${scriptFile}
  fi
  echo "" >> ${scriptFile}
done < <(grep -iro --color=never "(see Subpart [0-9]*\.[0-9]*)" html/${agencyName}/*.html | sort | uniq )

#in accordance with Subpart 25.7 (example in 25.501)
while read i; do
  echo "# ($i)" >> ${scriptFile}
  filename=""
  filename=$(cut -d: -f1 <<< "$i")
  if [ "${filename}" != "${i}" ] ; then
    txt=${i/${filename}:/}
    fullSection=${txt:27}
    fullSection=$(cut -d- -f1 <<< "$fullSection")

    echo "#I. ${txt} : fullSection: ${fullSection}" >> ${scriptFile}
    echo "#I. Replacing ${txt} in file ${filename}" >> ${scriptFile}
    echo "sed -i '' \"s|$txt|<a href=\\\"48.${ch}.${fullSection}.html\\\">$txt</a>|gI\" ${filename}" >> ${scriptFile}
  else
    echo "#I. NO FILENAME" >> ${scriptFile}
  fi
  echo "" >> ${scriptFile}
done < <(grep -iro --color=never "\bin accordance with Subpart [0-9]*\.[0-9]*\b" html/${agencyName}/*.html | sort | uniq )

#in accordance with 25.502 (example in 25.503)
while read i; do
  echo "# ($i)" >> ${scriptFile}
  filename=""
  filename=$(cut -d: -f1 <<< "$i")
  if [ "${filename}" != "${i}" ] ; then
    txt=${i/${filename}:/}
    fullSection=${txt:19}

    part=$(cut -d. -f1 <<< "$fullSection")

    section=$(cut -d. -f2 <<< "$fullSection")
    if [ "${#section}" == "3" ] ; then
      subpart=${section:0:1}
    elif [ "${#section}" == "4" ] ; then
      subpart=${section:0:2}
    else
      subpart=0
    fi
    echo "#J. ${txt} : fullSection: ${fullSection}, part: ${part}, subpart: ${subpart}" >> ${scriptFile}
    echo "#J. Replacing ${txt} in file ${filename}" >> ${scriptFile}
    echo "sed -i '' \"s|$txt|<a href=\\\"48.${ch}.${part}.${subpart}.html#48.${ch}.${fullSection}\\\">$txt</a>|gI\" ${filename}" >> ${scriptFile}
  else
    echo "#J. NO FILENAME" >> ${scriptFile}
  fi
  echo "" >> ${scriptFile}
done < <(grep -iro --color=never "\bin accordance with [0-9]*\.[0-9]*\b" html/${agencyName}/*.html | sort | uniq )

#provided in 25.105  (example in 25.502)
while read i; do
  echo "# ($i)" >> ${scriptFile}
  filename=""
  filename=$(cut -d: -f1 <<< "$i")
  if [ "${filename}" != "${i}" ] ; then
    txt=${i/${filename}:/}
    fullSection=${txt:12}

    part=$(cut -d. -f1 <<< "$fullSection")

    section=$(cut -d. -f2 <<< "$fullSection")
    if [ "${#section}" == "3" ] ; then
      subpart=${section:0:1}
    elif [ "${#section}" == "4" ] ; then
      subpart=${section:0:2}
    else
      subpart=0
    fi
    echo "#K. ${txt} : fullSection: ${fullSection}, part: ${part}, subpart: ${subpart}" >> ${scriptFile}
    echo "#K. Replacing ${txt} in file ${filename}" >> ${scriptFile}
    echo "sed -i '' \"s|$txt|<a href=\\\"48.${ch}.${part}.${subpart}.html#48.${ch}.${fullSection}\\\">$txt</a>|gI\" ${filename}" >> ${scriptFile}
  else
    echo "#K. NO FILENAME" >> ${scriptFile}
  fi
  echo "" >> ${scriptFile}
done < <(grep -iro --color=never "\bprovided in [0-9]*\.[0-9]*\b" html/${agencyName}/*.html | sort | uniq )

#(see 25.504-4, Example 2) (example in 25.503)
while read i; do
  echo "# ($i)" >> ${scriptFile}
  filename=""
  filename=$(cut -d: -f1 <<< "$i")
  if [ "${filename}" != "${i}" ] ; then
    txt=${i/${filename}:/}
    fullSection=${txt:5}
    fullSection=$(cut -d"-" -f1 <<< "$fullSection")

    part=$(cut -d. -f1 <<< "$fullSection")

    section=$(cut -d. -f2 <<< "$fullSection")
    if [ "${#section}" == "3" ] ; then
      subpart=${section:0:1}
    elif [ "${#section}" == "4" ] ; then
      subpart=${section:0:2}
    else
      subpart=0
    fi
    echo "#L. ${txt} : fullSection: ${fullSection}, part: ${part}, subpart: ${subpart}" >> ${scriptFile}
    echo "#L. Replacing ${txt} in file ${filename}" >> ${scriptFile}
    echo "sed -i '' \"s|$txt|<a href=\\\"48.${ch}.${part}.${subpart}.html#48.${ch}.${fullSection}\\\">$txt</a>|gI\" ${filename}" >> ${scriptFile}
  else
    echo "#L. NO FILENAME" >> ${scriptFile}
  fi
  echo "" >> ${scriptFile}
done < <(grep -iro --color=never "(see [0-9]*\.[0-9]*-[0-9]*, Example [0-9]*)" html/${agencyName}/*.html | sort | uniq )

#in 25.502(a)
while read i; do
  echo "# ($i)" >> ${scriptFile}
  filename=""
  filename=$(cut -d: -f1 <<< "$i")
  if [ "${filename}" != "${i}" ] ; then
    txt=${i/${filename}:/}
    fullSection=${txt:3}
    fullSection=$(cut -d"(" -f1 <<< "$fullSection")

    part=$(cut -d. -f1 <<< "$fullSection")

    section=$(cut -d. -f2 <<< "$fullSection")
    if [ "${#section}" == "3" ] ; then
      subpart=${section:0:1}
    elif [ "${#section}" == "4" ] ; then
      subpart=${section:0:2}
    else
      subpart=0
    fi
    echo "#M. ${txt} : fullSection: ${fullSection}, part: ${part}, subpart: ${subpart}" >> ${scriptFile}
    echo "#M. Replacing ${txt} in file ${filename}" >> ${scriptFile}
    echo "sed -i '' \"s|$txt|<a href=\\\"48.${ch}.${part}.${subpart}.html#48.${ch}.${fullSection}\\\">$txt</a>|gI\" ${filename}" >> ${scriptFile}
  else
    echo "#M. NO FILENAME" >> ${scriptFile}
  fi
  echo "" >> ${scriptFile}
done < <(grep -iro --color=never "in [0-9]*\.[0-9]*([a-z])" html/${agencyName}/*.html | sort | uniq )

#(see 25.502(c)(4)(ii)) (Example in 25.504-1)
while read i; do
  echo "# ($i)" >> ${scriptFile}
  filename=""
  filename=$(cut -d: -f1 <<< "$i")
  if [ "${filename}" != "${i}" ] ; then
    txt=${i/${filename}:/}
    fullSection=${txt:5}
    fullSection=$(cut -d"(" -f1 <<< "$fullSection")

    part=$(cut -d. -f1 <<< "$fullSection")

    section=$(cut -d. -f2 <<< "$fullSection")
    if [ "${#section}" == "3" ] ; then
      subpart=${section:0:1}
    elif [ "${#section}" == "4" ] ; then
      subpart=${section:0:2}
    else
      subpart=0
    fi
    echo "#N. ${txt} : fullSection: ${fullSection}, part: ${part}, subpart: ${subpart}" >> ${scriptFile}
    echo "#N. Replacing ${txt} in file ${filename}" >> ${scriptFile}
    echo "sed -i '' \"s|$txt|<a href=\\\"48.${ch}.${part}.${subpart}.html#48.${ch}.${fullSection}\\\">$txt</a>|gI\" ${filename}" >> ${scriptFile}
  else
    echo "#N. NO FILENAME" >> ${scriptFile}
  fi
  echo "" >> ${scriptFile}
done < <(grep -iro --color=never "(see [0-9]*\.[0-9]*([a-z]*)([0-9]*)([a-z]*))" html/${agencyName}/*.html | sort | uniq )

#of 52.225-9 | at 52.225-9 | or 52.225-9
while read i; do
  echo "# ($i)" >> ${scriptFile}
  filename=""
  filename=$(cut -d: -f1 <<< "$i")
  if [ "${filename}" != "${i}" ] ; then
    txt=${i/${filename}:/}
    fullSection=${txt:3}
    fullSection=$(cut -d"-" -f1 <<< "$fullSection")

    part=$(cut -d. -f1 <<< "$fullSection")

    section=$(cut -d. -f2 <<< "$fullSection")
    if [ "${#section}" == "3" ] ; then
      subpart=${section:0:1}
    elif [ "${#section}" == "4" ] ; then
      subpart=${section:0:2}
    else
      subpart=0
    fi
    echo "#O. ${txt} : fullSection: ${fullSection}, part: ${part}, subpart: ${subpart}" >> ${scriptFile}
    echo "#O. Replacing ${txt} in file ${filename}" >> ${scriptFile}
    echo "sed -i '' \"s|$txt|<a href=\\\"48.${ch}.${part}.${subpart}.html#48.${ch}.${fullSection}\\\">$txt</a>|gI\" ${filename}" >> ${scriptFile}
  else
    echo "#O. NO FILENAME" >> ${scriptFile}
  fi
  echo "" >> ${scriptFile}
done < <(grep -iro --color=never -e "\bof [0-9]*\.[0-9]*-[0-9]*\b" -e "\bin [0-9]*\.[0-9]*-[0-9]*\b" -e "\bat [0-9]*\.[0-9]*-[0-9]*\b" -e "\bor [0-9]*\.[0-9]*-[0-9]*\b" html/${agencyName}/*.html | sort | uniq )

#either 52.225-9
while read i; do
  echo "# ($i)" >> ${scriptFile}
  filename=""
  filename=$(cut -d: -f1 <<< "$i")
  if [ "${filename}" != "${i}" ] ; then
    txt=${i/${filename}:/}
    fullSection=${txt:7}
    fullSection=$(cut -d"-" -f1 <<< "$fullSection")

    part=$(cut -d. -f1 <<< "$fullSection")

    section=$(cut -d. -f2 <<< "$fullSection")
    if [ "${#section}" == "3" ] ; then
      subpart=${section:0:1}
    elif [ "${#section}" == "4" ] ; then
      subpart=${section:0:2}
    else
      subpart=0
    fi
    echo "#P. ${txt} : fullSection: ${fullSection}, part: ${part}, subpart: ${subpart}" >> ${scriptFile}
    echo "#P. Replacing ${txt} in file ${filename}" >> ${scriptFile}
    echo "sed -i '' \"s|$txt|<a href=\\\"48.${ch}.${part}.${subpart}.html#48.${ch}.${fullSection}\\\">$txt</a>|gI\" ${filename}" >> ${scriptFile}
  else
    echo "#P. NO FILENAME" >> ${scriptFile}
  fi
  echo "" >> ${scriptFile}
done < <(grep -iro --color=never -e "\beither [0-9]*\.[0-9]*-[0-9]*\b"  html/${agencyName}/*.html | sort | uniq )

#in subpart 25.5 | at Subpart 25.5
while read i; do
  echo "# ($i)" >> ${scriptFile}
  filename=""
  filename=$(cut -d: -f1 <<< "$i")
  if [ "${filename}" != "${i}" ] ; then
    txt=${i/${filename}:/}
    fullSection=${txt:11}

    echo "#S. ${txt} : fullSection: ${fullSection}, part: ${part}, subpart: ${subpart}" >> ${scriptFile}
    echo "#S. Replacing ${txt} in file ${filename}" >> ${scriptFile}
    echo "sed -i '' \"s|$txt|<a href=\\\"48.${ch}.${fullSection}.html\\\">$txt</a>|gI\" ${filename}" >> ${scriptFile}
  else
    echo "#Q. NO FILENAME" >> ${scriptFile}
  fi
  echo "" >> ${scriptFile}
done < <(grep -iro --color=never -e "\bin subpart [0-9]*\.[0-9]*\b"  -e "\bat subpart [0-9]*\.[0-9]*\b" html/${agencyName}/*.html | sort | uniq )

#see subpart 25.5
while read i; do
  echo "# ($i)" >> ${scriptFile}
  filename=""
  filename=$(cut -d: -f1 <<< "$i")
  if [ "${filename}" != "${i}" ] ; then
    txt=${i/${filename}:/}
    fullSection=${txt:12}

    echo "#S. ${txt} : fullSection: ${fullSection}, part: ${part}, subpart: ${subpart}" >> ${scriptFile}
    echo "#S. Replacing ${txt} in file ${filename}" >> ${scriptFile}
    echo "sed -i '' \"s|$txt|<a href=\\\"48.${ch}.${fullSection}.html\\\">$txt</a>|gI\" ${filename}" >> ${scriptFile}
  else
    echo "#R. NO FILENAME" >> ${scriptFile}
  fi
  echo "" >> ${scriptFile}
done < <(grep -iro --color=never -e "\bsee subpart [0-9]*\.[0-9]*\b"   html/${agencyName}/*.html | sort | uniq )

#under subpart 25.5
while read i; do
  echo "# ($i)" >> ${scriptFile}
  filename=""
  filename=$(cut -d: -f1 <<< "$i")
  if [ "${filename}" != "${i}" ] ; then
    txt=${i/${filename}:/}
    fullSection=${txt:14}

    echo "#S. ${txt} : fullSection: ${fullSection}, part: ${part}, subpart: ${subpart}" >> ${scriptFile}
    echo "#S. Replacing ${txt} in file ${filename}" >> ${scriptFile}
    echo "sed -i '' \"s|$txt|<a href=\\\"48.${ch}.${fullSection}.html\\\">$txt</a>|gI\" ${filename}" >> ${scriptFile}
  else
    echo "#S. NO FILENAME" >> ${scriptFile}
  fi
  echo "" >> ${scriptFile}
done < <(grep -iro --color=never -e "\bunder subpart [0-9]*\.[0-9]*\b"  html/${agencyName}/*.html | sort | uniq )

#under 25.202(a)
while read i; do
  echo "# ($i)" >> ${scriptFile}
  filename=""
  filename=$(cut -d: -f1 <<< "$i")
  if [ "${filename}" != "${i}" ] ; then
    txt=${i/${filename}:/}
    fullSection=${txt:6}
    fullSection=$(cut -d"(" -f1 <<< "$fullSection")

    part=$(cut -d. -f1 <<< "$fullSection")
    section=$(cut -d. -f2 <<< "$fullSection")
    if [ "${#section}" == "3" ] ; then
      subpart=${section:0:1}
    elif [ "${#section}" == "4" ] ; then
      subpart=${section:0:2}
    else
      subpart=0
    fi
    echo "#T. ${txt} : fullSection: ${fullSection}, part: ${part}, subpart: ${subpart}" >> ${scriptFile}
    echo "#T. Replacing ${txt} in file ${filename}" >> ${scriptFile}
    echo "sed -i '' \"s|$txt|<a href=\\\"48.${ch}.${part}.${subpart}.html#48.${ch}.${fullSection}\\\">$txt</a>|gI\" ${filename}" >> ${scriptFile}
  else
    echo "#T. NO FILENAME" >> ${scriptFile}
  fi
  echo "" >> ${scriptFile}
done < <(grep -iro --color=never -e "\bunder [0-9]*\.[0-9]*([a-z]*)\b"  html/${agencyName}/*.html | sort | uniq )

#at 25.202(a) | in 25.202(a)
while read i; do
  echo "# ($i)" >> ${scriptFile}
  filename=""
  filename=$(cut -d: -f1 <<< "$i")
  if [ "${filename}" != "${i}" ] ; then
    txt=${i/${filename}:/}
    fullSection=${txt:3}
    fullSection=$(cut -d"(" -f1 <<< "$fullSection")

    part=$(cut -d. -f1 <<< "$fullSection")
    section=$(cut -d. -f2 <<< "$fullSection")
    if [ "${#section}" == "3" ] ; then
      subpart=${section:0:1}
    elif [ "${#section}" == "4" ] ; then
      subpart=${section:0:2}
    else
      subpart=0
    fi
    echo "#U. ${txt} : fullSection: ${fullSection}, part: ${part}, subpart: ${subpart}" >> ${scriptFile}
    echo "#U. Replacing ${txt} in file ${filename}" >> ${scriptFile}
    echo "sed -i '' \"s|$txt|<a href=\\\"48.${ch}.${part}.${subpart}.html#48.${ch}.${fullSection}\\\">$txt</a>|gI\" ${filename}" >> ${scriptFile}
  else
    echo "#U. NO FILENAME" >> ${scriptFile}
  fi
  echo "" >> ${scriptFile}
done < <(grep -iro --color=never -e "\bat [0-9]*\.[0-9]*([a-z]*)\b" -e "\bin [0-9]*\.[0-9]*([a-z]*)\b" html/${agencyName}/*.html | sort | uniq )

#in 1.201-1
while read i; do
  echo "# ($i)" >> ${scriptFile}
  filename=""
  filename=$(cut -d: -f1 <<< "$i")
  if [ "${filename}" != "${i}" ] ; then
    txt=${i/${filename}:/}
    fullSection=${txt:3}
    fullSection=$(cut -d"-" -f1 <<< "$fullSection")

    part=$(cut -d. -f1 <<< "$fullSection")
    section=$(cut -d. -f2 <<< "$fullSection")
    if [ "${#section}" == "3" ] ; then
      subpart=${section:0:1}
    elif [ "${#section}" == "4" ] ; then
      subpart=${section:0:2}
    else
      subpart=0
    fi
    echo "#V. ${txt} : fullSection: ${fullSection}, part: ${part}, subpart: ${subpart}" >> ${scriptFile}
    echo "#V. Replacing ${txt} in file ${filename}" >> ${scriptFile}
    echo "sed -i '' \"s|$txt|<a href=\\\"48.${ch}.${part}.${subpart}.html#48.${ch}.${fullSection}\\\">$txt</a>|gI\" ${filename}" >> ${scriptFile}
  else
    echo "#V. NO FILENAME" >> ${scriptFile}
  fi
  echo "" >> ${scriptFile}
done < <(grep -iro --color=never -e "\bin [0-9]*\.[0-9]*-[0-9]*\b"  html/${agencyName}/*.html | sort | uniq )

#under subsection 25.702-2
while read i; do
  echo "# ($i)" >> ${scriptFile}
  filename=""
  filename=$(cut -d: -f1 <<< "$i")
  if [ "${filename}" != "${i}" ] ; then
    txt=${i/${filename}:/}
    fullSection=${txt:11}
    fullSection=$(cut -d"-" -f1 <<< "$fullSection")

    part=$(cut -d. -f1 <<< "$fullSection")
    section=$(cut -d. -f2 <<< "$fullSection")
    if [ "${#section}" == "3" ] ; then
      subpart=${section:0:1}
    elif [ "${#section}" == "4" ] ; then
      subpart=${section:0:2}
    else
      subpart=0
    fi
    echo "#W. ${txt} : fullSection: ${fullSection}, part: ${part}, subpart: ${subpart}" >> ${scriptFile}
    echo "#W. Replacing ${txt} in file ${filename}" >> ${scriptFile}
    echo "sed -i '' \"s|$txt|<a href=\\\"48.${ch}.${part}.${subpart}.html#48.${ch}.${fullSection}\\\">$txt</a>|gI\" ${filename}" >> ${scriptFile}
  else
    echo "#W. NO FILENAME" >> ${scriptFile}
  fi
  echo "" >> ${scriptFile}
done < <(grep -iro -e "subsection [0-9]*\.[0-9]*-[(0-9)*]"  html/${agencyName}/*.html | sort | uniq)

chmod +x ${scriptFile}
./${scriptFile}
