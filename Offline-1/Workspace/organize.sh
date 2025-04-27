#!/usr/bin/env bash

# usage: ./organize.sh <submissions_dir> <target_dir> <tests_dir> <answers_dir> [ -v ] [ -noexecute ] [ -nolc ] [ -nocc ] [ -nofc ]
usage() {
  echo "Usage: $0 <submissions_dir> <target_dir> <tests_dir> <answers_dir> [-v] [-noexecute] [-nolc] [-nocc] [-nofc]"
  exit 1
}

# 2. Ensure minimum arguments
if [ $# -lt 4 ]; then
  echo "Error: too few arguments."
  usage
fi

# 3. Mandatory arguments
SUBM_DIR="$1"      # submissions folder
TARGET_DIR="$2"    # where we'll build targets/
TEST_DIR="$3"      # tests/
ANS_DIR="$4"       # answers/

shift 4  # remove those from $@

# 4. Default optional flags
VERBOSE=false
NOEXECUTE=false
CALC_LC=true
CALC_CC=true
CALC_FC=true

# Parse any remaining flags
for arg in "$@"; do
  case "$arg" in
    -v)            VERBOSE=true ;;
    -noexecute)    NOEXECUTE=true ;;
    -nolc)         CALC_LC=false ;;
    -nocc)         CALC_CC=false ;;
    -nofc)         CALC_FC=false ;;
    *) echo "Unknown option: $arg"; usage ;;
  esac
done

# Debug print if verbose
if [ "$VERBOSE" = true ]; then
  echo ">> submissions: $SUBM_DIR"
  echo ">> targets:     $TARGET_DIR"
  echo ">> tests:       $TEST_DIR"
  echo ">> answers:     $ANS_DIR"
  echo ">> verbose      $VERBOSE"
  echo ">> noexecute    $NOEXECUTE"
  echo ">> calc_lc      $CALC_LC"
  echo ">> calc_cc      $CALC_CC"
  echo ">> calc_fc      $CALC_FC"
fi

# (Next: Task A – create target dirs & unzip + organize codes)
