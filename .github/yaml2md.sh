#!/bin/bash

echo "| Name | Category | Version |"
echo "|------|----------|---------|"

yq e '.[] | [.name, .category, .version] | @tsv' versions.yaml | while IFS=$'\t' read -r name category version
do
  echo "| $name | $category | $version |"
done