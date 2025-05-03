#!/usr/bin/env bash

# usage: ./organize.sh <submissions_dir> <target_dir> <tests_dir> <answers_dir> [ -v ] [ -noexecute ] [ -nolc ] [ -nocc ] [ -nofc ]
usage() {
  echo "Usage: $0 <submissions_dir> <target_dir> <tests_dir> <answers_dir> [-v] [-noexecute] [-nolc] [-nocc] [-nofc]"
  exit 1
}

# Check mandatory args
if [ $# -lt 4 ]; then
  echo "Error: too few arguments."
  usage
fi

SUBM_DIR="$1"      # submissions folder
TARGET_DIR="$2"    # where we'll build targets/
TEST_DIR="$3"      # tests/
ANS_DIR="$4"       # answers/

shift 4 

# Default optional flags
VERBOSE=false
NOEXECUTE=false
CALC_LC=true
CALC_CC=true
CALC_FC=true


# Parse optional flags
for optional_arg in "$@"; do
  case "$optional_arg" in
    -v)            
      VERBOSE=true 
    ;;
    -noexecute)    
      NOEXECUTE=true 
    ;;
    -nolc)         
      CALC_LC=false 
    ;;
    -nocc)         
      CALC_CC=false 
    ;;
    -nofc)         
      CALC_FC=false 
    ;;
    *) # Base case 
      echo "Unknown option: $optional_arg"; 
        usage 
      ;;
  esac
done

# Debug print if verbose
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

### ===Task A: Organize===
mkdir -p "$TARGET_DIR"/{C,C++,Python,Java}

# CSV header
header="student_id,student_name,language"
if [ "$NOEXECUTE" != true ]; then
  header+=",matched,not_matched"
fi
$CALC_LC && header+=",line_count"
$CALC_CC && header+=",comment_count"
$CALC_FC && header+=",function_count"
echo "$header" > "$TARGET_DIR/result.csv"

# process each student ZIP
for zipfile in "$SUBM_DIR"/*.zip; do
  [ -e "$zipfile" ] || { echo "No .zip files in $SUBM_DIR"; break; }

  filename=$(basename "$zipfile")
  student_name="${filename%%_*}" # %%_* means "delete everything from the first underscore to the end"
  student_id="${filename##*_}" # ##*_ means "delete everything from the beginning up to the last underscore"
  student_id="${student_id%.zip}" # % is another parameter expansion that removes the shortest matching pattern from the end

  ## Debug Info
  # $VERBOSE && echo "Zipfile Name: $zipfile"
  # $VERBOSE && echo "File Name: $filename"
  # $VERBOSE && echo "Student Name: $student_name"
  # $VERBOSE && echo "Student Id: $student_id"

  # $VERBOSE && echo
  # $VERBOSE && echo "=== Processing $student_name ($student_id) ==="
  $VERBOSE && echo "Processing files of $student_id"

  # Unzip into temp
  tmpdir=$(mktemp -d) || { echo "ERROR: cannot create temp dir"; exit 1; }
  unzip -q "$zipfile" -d "$tmpdir"

  # Find the single code file (recursive)
  codefile=$(find "$tmpdir" -type f \
    \( -iname '*.c' -o -iname '*.cpp' -o -iname '*.java' -o -iname '*.py' \) \
    | sort | head -n1)

  if [ -z "$codefile" ]; then
    echo "WARNING: no code file in $filename"
    rm -rf "$tmpdir"
    continue
  fi
  # $VERBOSE && echo " Found code: $codefile"

  # Determine language & target name
  case "${codefile,,}" in
    *.c)    lang="C";     target_name="main.c"   ;;
    *.cpp)  lang="C++";   target_name="main.cpp" ;;
    *.java) lang="Java";  target_name="Main.java";;
    *.py)   lang="Python";target_name="main.py";;
  esac

  # Copy into targets/{Lang}/{ID}/
  dest="$TARGET_DIR/$lang/$student_id"
  mkdir -p "$dest"
  cp "$codefile" "$dest/$target_name"
  # $VERBOSE && echo " Copied → $dest/$target_name"

  rm -rf "$tmpdir"

  ### ===Task B: Code Analysis===
  source_file="$dest/$target_name"

  if [ "$CALC_LC" = true ]; then
    lc=$(wc -l < "$source_file" | tr -d '[:space:]')
  else
    lc=""
  fi

  # Comment Count
  if [ "$CALC_CC" = true ]; then
    # Using sed to strip out string literals, first remove all inside double quotation or single quotation and then count the // or # marks (once in a line so multiple spanning will not affect the count)
    if [ "$lang" = "Python" ]; then
      cc=$(sed -E 's/"([^"\\]|\\.)*"//g; s/'"'"'([^'"'"'\]|\\.)*'"'"'//g' "$source_file" | grep -c '#')
    else
      cc=$(sed -E 's/"([^"\\]|\\.)*"//g; s/'"'"'([^'"'"'\]|\\.)*'"'"'//g' "$source_file" | grep -c '//')
    fi
  else
    cc=""
  fi

  # Function Count
  if [ "$CALC_FC" = true ]; then
    case "$lang" in
      C|C++)
          fc=$(grep -E '^[[:space:]]*[A-Za-z_][A-Za-z0-9_]+[[:space:]]+[A-Za-z_][A-Za-z0-9_]+[[:space:]]*\([^)]*\)[[:space:]]*\{' "$source_file" | wc -l)
        ;;
      Java)
          fc=$(grep -E '^[[:space:]]*([A-Za-z_$][A-Za-z0-9_$<>]*[[:space:]]+)+[A-Za-z_$][A-Za-z0-9_$]*[[:space:]]*\([^)]*\)[[:space:]]*\{' "$source_file" | wc -l)
        ;;
      Python)
          fc=$(grep -c '^[[:space:]]*def ' "$source_file")
        ;;
    esac
  else
    fc=""
  fi

  # $VERBOSE && echo " Metrics → lines:$lc  comments:$cc  functions:$fc"

  ### ===Task C: Execute and Match===
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

  # Append this student’s row to CSV
  row="$student_id,\"$student_name\",$lang"
  [ "$NOEXECUTE" = false ] && row+=",${matched},${not_matched}"
  [ "$CALC_LC"    = true ] && row+=",${lc}"
  [ "$CALC_CC"    = true ] && row+=",${cc}"
  [ "$CALC_FC"    = true ] && row+=",${fc}"
  echo "$row" >> "$TARGET_DIR/result.csv"


done

$VERBOSE && echo "All submissions processed successfully."

# Kill the script 
# kill -INT $$