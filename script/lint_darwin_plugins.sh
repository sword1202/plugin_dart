#!/bin/bash

# This script lints and tests iOS and macOS platform code.

# So that users can run this script from anywhere and it will work as expected.
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
readonly REPO_DIR="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/common.sh"

function lint_package() {
  local package_name="$1"
  local package_dir="${REPO_DIR}/packages/$package_name/"
  local failure_count=0

  # These podspecs are temporary multi-platform adoption dummy files.
  local skipped_podspecs=(
    "url_launcher_web.podspec"
  )
  
  # TODO: These packages have analyzer warnings. Remove plugins from this list as issues are fixed.
  local skip_analysis_packages=(
    "camera.podspec" # https://github.com/flutter/flutter/issues/42673
  )
  find "${package_dir}" -type f -name "*\.podspec" | while read podspec; do
    local podspecBasename=$(basename "${podspec}")
    if [[ "${skipped_podspecs[*]}" =~ "${podspecBasename}" ]]; then
      continue
    fi

    # TODO: Remove --allow-warnings flag https://github.com/flutter/flutter/issues/41444
    local lint_args=(
      lib
      lint
      "${podspec}"
      --allow-warnings
      --fail-fast
      --silent
    )
    if [[ ! "${skip_analysis_packages[*]}" =~ "${podspecBasename}" ]]; then
      lint_args+=(--analyze)
      echo "Linting and analyzing ${podspecBasename}"
    else
      echo "Linting ${podspecBasename}"
    fi

    # Build as frameworks.
    # This will also run any tests set up as a test_spec. See https://blog.cocoapods.org/CocoaPods-1.3.0.
    pod "${lint_args[@]}"
    if [[ "$?" -ne 0 ]]; then
      error "Package ${package_name} has framework issues. Run \"pod lib lint ${podspec} --analyze\" to inspect."
      failure_count+=1
    fi

    # Build as libraries.
    lint_args+=(--use-libraries)
    pod "${lint_args[@]}"
    if [[ "$?" -ne 0 ]]; then
      error "Package ${package_name} has library issues. Run \"pod lib lint ${podspec} --use-libraries --analyze\" to inspect."
      failure_count+=1
    fi
  done

  return "${failure_count}"
}

function lint_packages() {
  if [[ ! "$(which pod)" ]]; then 
    echo "pod not installed. Skipping."
    return
  fi

  local failure_count=0
  for package_name in "$@"; do   
    lint_package "${package_name}"
    failure_count+="$?"
  done

  return "${failure_count}"
}

# Sets CHANGED_PACKAGE_LIST
check_changed_packages

if [[ "${#CHANGED_PACKAGE_LIST[@]}" != 0 ]]; then
  lint_packages "${CHANGED_PACKAGE_LIST[@]}"
fi
