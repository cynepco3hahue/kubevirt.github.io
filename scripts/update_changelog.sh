#!/bin/bash
# Description: This script generates markdown files for each release of kubevirt in repository
# Generated markdown files should be stored under _posts/ for website rendering

TARGET='build'
mkdir -p build/artifacts
[[ -e build/kubevirt ]] || git clone git@github.com:kubevirt/kubevirt.git build/
git -C build/kubevirt checkout master
git -C build/kubevirt pull --tags

releases() {
git -C kubevirt tag | sort -rV | while read TAG ;
do
  [[ "$TAG" =~ [0-9].0$ ]] || continue ;
  # Skip following releases as there's a manual article for them
  [[ "$TAG" == "v0.1.0" ]] && continue ;
  [[ "$TAG" == "v0.2.0" ]] && continue ;
  echo "$TAG" ;
done
}

features_for() {
  echo -e  ""
  git -C kubevirt show $1 | grep Date: | head -n1 | sed "s/Date:\s\+/Released on: /"
  echo -e  ""
  git -C kubevirt show $1 | sed -n "/changes$/,/Contributors/ p" | egrep "^- " ;
}

gen_changelog() {
  {
  for REL in $(releases);
  do
    FILENAME="changelog-$REL.markdown"
    cat <<EOF >  $FILENAME
---
layout: post
author: kubebot
description: This article provides information about Kube Virt release $REL changes
navbar_active: Blogs
datefixme:
category: releases
comments: true
title: Kube Virt $REL
pub-date: July 23
pub-year: 2018
---

EOF

    (
    echo -e "\n## $REL" ;
    features_for $REL
    )>> "$FILENAME"
    daterelease=$(cat "$FILENAME"| grep "Released on" |cut -d ":" -f 2-)
    sed -i "s#^datefixme: #date: $daterelease#g" "$FILENAME"
    newdate=$(echo $daterelease|tr " " "\n"|grep -v "+"|tr "\n" " ")
    year=$(date --date="$newdate" '+%Y')
    month=$(date --date="$newdate" '+%m')
    monthname=$(LANG=C date --date="$newdate" '+%B')
    day=$(date --date="$newdate" '+%d')
    NEWFILENAME="build/artifacts/$year-$month-$day-$FILENAME"
    mv $FILENAME $NEWFILENAME
    sed -i "s#^pub-date:.*#pub-date: $monthname#g" "$NEWFILENAME"
    sed -i "s#^pub-year:.*#pub-year: $year#g" "$NEWFILENAME"
  done
  }
}

gen_changelog

for file in build/artifacts/*.md; do
[ -f $(filename _posts/$file) ] || mv $file _posts/
done

git add _posts/
git commit -m "Release autobot 🤖"
git push