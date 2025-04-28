#!/usr/bin/env bash

# usage: ./organize.sh <submissions_dir> <target_dir> <tests_dir> <answers_dir> [ -v ] [ -noexecute ] [ -nolc ] [ -nocc ] [ -nofc ]
usage() {
  echo "Usage: $0 <submissions_dir> <target_dir> <tests_dir> <answers_dir> [-v] [-noexecute] [-nolc] [-nocc] [-nofc]"
  exit 1
}

# 1. Check mandatory args
if [ $# -lt 4 ]; then
  echo "Error: too few arguments."
  usage
fi

SUBM_DIR="$1"      # submissions folder
TARGET_DIR="$2"    # where we'll build targets/
TEST_DIR="$3"      # tests/
ANS_DIR="$4"       # answers/

shift 4 

# 2. Default optional flags
VERBOSE=false
NOEXECUTE=false
CALC_LC=true
CALC_CC=true
CALC_FC=true

# 3. Parse optional flags
for optional_arg in "$@"; do
  case "$optional_arg" in
    -v)            VERBOSE=true ;;
    -noexecute)    NOEXECUTE=true ;;
    -nolc)         CALC_LC=false ;;
    -nocc)         CALC_CC=false ;;
    -nofc)         CALC_FC=false ;;
    *) echo "Unknown option: $optional_arg"; usage ;;
  esac
done

# 4. Debug print if verbose
# if [ "$VERBOSE" = true ]; then
#   echo ">> submissions: $SUBM_DIR"
#   echo ">> targets:     $TARGET_DIR"
#   echo ">> tests:       $TEST_DIR"
#   echo ">> answers:     $ANS_DIR"
#   echo ">> verbose:     $VERBOSE"
#   echo ">> noexecute:   $NOEXECUTE"
#   echo ">> calc_lc:     $CALC_LC"
#   echo ">> calc_cc:     $CALC_CC"
#   echo ">> calc_fc:     $CALC_FC"
# fi

# 5. Task A: create language directories under targets
mkdir -p "$TARGET_DIR"/{C,C++,Python,Java}

# 6. Task B.0: write CSV header (once)
header="student_id,student_name,language"
if [ "$NOEXECUTE" != true ]; then
  header+=",matched,not_matched"
fi
$CALC_LC && header+=",line_count"
$CALC_CC && header+=",comment_count"
$CALC_FC && header+=",function_count"
echo "$header" > "$TARGET_DIR/result.csv"

# 7. Main loop: process each student ZIP
for zipfile in "$SUBM_DIR"/*.zip; do
  [ -e "$zipfile" ] || { echo "No .zip files in $SUBM_DIR"; break; }

  filename=$(basename "$zipfile")
  student_name="${filename%%_*}"
  student_id="${filename##*_}"
  student_id="${student_id%.zip}"

  # $VERBOSE && echo
  # $VERBOSE && echo "=== Processing $student_name ($student_id) ==="
  $VERBOSE && echo "Processing files of $student_id"

  # 7.a Unzip into temp
  tmpdir=$(mktemp -d) || { echo "ERROR: cannot create temp dir"; exit 1; }
  unzip -q "$zipfile" -d "$tmpdir"

  # 7.b Find the single code file (recursive)
  codefile=$(find "$tmpdir" -type f \
    \( -iname '*.c' -o -iname '*.cpp' -o -iname '*.java' -o -iname '*.py' \) \
    | sort | head -n1)

  if [ -z "$codefile" ]; then
    echo "WARNING: no code file in $filename"
    rm -rf "$tmpdir"
    continue
  fi
  # $VERBOSE && echo " Found code: $codefile"

  # 7.c Determine language & target name
  case "${codefile,,}" in
    *.c)    lang="C";     target_name="main.c"   ;;
    *.cpp)  lang="C++";   target_name="main.cpp" ;;
    *.java) lang="Java";  target_name="Main.java";;
    *.py)   lang="Python";target_name="main.py";;
  esac

  # 7.d Copy into targets/{Lang}/{ID}/
  dest="$TARGET_DIR/$lang/$student_id"
  mkdir -p "$dest"
  cp "$codefile" "$dest/$target_name"
  # $VERBOSE && echo " Copied → $dest/$target_name"

  rm -rf "$tmpdir"

  #
  # 7.e Task B.1: Compute code metrics
  #
  source_file="$dest/$target_name"

  if [ "$CALC_LC" = true ]; then
    lc=$(wc -l < "$source_file" | tr -d '[:space:]')
  else
    lc=""
  fi

  if [ "$CALC_CC" = true ]; then
    if [ "$lang" = "Python" ]; then
      # count any line with a '#' anywhere
      cc=$(grep -c '#' "$source_file")
    else
      # count any line with '//' anywhere (inline or full-line)
      cc=$(grep -c '//' "$source_file")
    fi
  else
    cc=""
  fi

  if [ "$CALC_FC" = true ]; then
    case "$lang" in
      C|C++)
        fc=$(grep -E '^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]+[A-Za-z_][A-Za-z0-9_]*[[:space:]]*\([^)]*\)[[:space:]]*\{' \
              "$source_file" | wc -l)
        ;;
      Java)
        fc=$(grep -E '^[[:space:]]*([A-Za-z_$][A-Za-z0-9_$<>]*[[:space:]]+)+[A-Za-z_$][A-Za-z0-9_$]*[[:space:]]*\([^)]*\)[[:space:]]*\{' \
              "$source_file" | wc -l)
        ;;
      Python)
        fc=$(grep -c '^[[:space:]]*def ' "$source_file")
        ;;
    esac
  else
    fc=""
  fi

  # $VERBOSE && echo " Metrics → lines:$lc  comments:$cc  functions:$fc"

  #
  # 7.f Task C: compile, run tests, diff
  #
  matched=0
  not_matched=0

  if [ "$NOEXECUTE" = false ]; then
    $VERBOSE && echo "Executing files of $student_id"

    # compile / set execute command
    case "$lang" in
      C)
        gcc "$source_file" -o "$dest/main.out"
        exe="$dest/main.out"
        ;;
      "C++")
        g++ "$source_file" -o "$dest/main.out"
        exe="$dest/main.out"
        ;;
      Java)
        javac -d "$dest" "$dest/Main.java"
        exe="java -cp $dest Main"
        ;;
      Python)
        exe="python3 $dest/main.py"
        ;;
    esac

    # run each test
    for testfile in "$TEST_DIR"/test*.txt; do
      testname=$(basename "$testfile")
      idx="${testname#test}"
      idx="${idx%.txt}"
      outfile="$dest/out${idx}.txt"

      # $VERBOSE && echo "  Test #$idx → $outfile"
      $exe < "$testfile" > "$outfile"

      ansfile="$ANS_DIR/ans${idx}.txt"
      if diff -q "$outfile" "$ansfile" > /dev/null; then
        matched=$((matched+1))
      else
        not_matched=$((not_matched+1))
      fi
    done

    # $VERBOSE && echo "  Results → matched:$matched  not_matched:$not_matched"
  fi

  #
  # 7.g Append this student’s row to CSV
  #
  row="$student_id,\"$student_name\",$lang"
  [ "$NOEXECUTE" = false ] && row+=",${matched},${not_matched}"
  [ "$CALC_LC"    = true ] && row+=",${lc}"
  [ "$CALC_CC"    = true ] && row+=",${cc}"
  [ "$CALC_FC"    = true ] && row+=",${fc}"
  echo "$row" >> "$TARGET_DIR/result.csv"


done

$VERBOSE && echo "All submissions processed successfully."