#!/bin/bash

# This script is used to generate a PR message for bumping Kairos repositories.
# It compares the versions of the packages in the old and new repositories and
# generates a message with the differences.
# It expects the following files to be present in the current directory:
# - versions.old.yaml -> from the old repository framework image
# - versions.new.yaml -> from the new repository framework image
# - versions-fips.old.yaml -> from the old repository fips image
# - versions-fips.new.yaml -> from the new repository fips image

stat versions.old.yaml > /dev/null 2>&1
if [[ $? != 0 ]]; then
  echo "versions.old.yaml not found"
  exit 1
fi
stat versions.new.yaml > /dev/null 2>&1
if [[ $? != 0 ]]; then
  echo "versions.new.yaml not found"
  exit 1
fi
stat versions-fips.old.yaml > /dev/null 2>&1
if [[ $? != 0 ]]; then
  echo "versions_fips.old.yaml not found"
  exit 1
fi
stat versions-fips.new.yaml > /dev/null 2>&1
if [[ $? != 0 ]]; then
  echo "versions_fips.new.yaml not found"
  exit 1
fi

# Merge and sort versions files
yq -P '.|=sort_by(.name, .category)|.[]|[{"name": .name, "category": .category, "version": .version}]' versions.old.yaml versions-fips.old.yaml > merged.old.yaml
yq -P '.|=sort_by(.name, .category)|.[]|[{"name": .name, "category": .category, "version": .version}]' versions.new.yaml versions-fips.new.yaml > merged.new.yaml
# Remove yaml separator
sed -i 's|---||g' merged.old.yaml
sed -i 's|---||g' merged.new.yaml
# Remove empty lines
sed -i '/^$/d' merged.old.yaml
sed -i '/^$/d' merged.new.yaml


echo "Bump of Kairos repositories" > pr-message
echo "--------------------------" >> pr-message
DIFF=$(diff -L "Old repo" -L "New Repo" -u merged.old.yaml merged.new.yaml)
if [[ $? == 1 ]]; then
  {
    echo "> [\!WARNING]"
    echo "> There were changes to installed packages"
    echo "\`\`\`diff"
    echo "${DIFF}"
    echo "\`\`\`"
    echo
  } >> pr-message
fi
{
  echo "> [\!IMPORTANT]"
  echo "> Full package list from new repo"
  echo ""
  echo "| Name | Category | Version |"
  echo "|------|----------|---------|"
  yq e '.[] | [.name, .category, .version] | @tsv' merged.new.yaml | while IFS=$'\t' read -r name category version
  do
    echo "| $name | $category | $version |"
  done
  echo ""
} >> pr-message
