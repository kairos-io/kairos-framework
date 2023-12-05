#!/bin/bash


if [ "$1" == "" ];then
  FILE=versions.yaml
else
  FILE=$1
fi
echo "| Name | Category | Version |"
echo "|------|----------|---------|"

yq e '.[] | [.name, .category, .version] | @tsv' "${FILE}" | while IFS=$'\t' read -r name category version
do
  echo "| $name | $category | $version |"
done

echo ""