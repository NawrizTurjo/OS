# #!/usr/bin/env bash

# # usage: ./organize.sh <submissions_dir> <target_dir> <tests_dir> <answers_dir> [ -v ] [ -noexecute ] [ -nolc ] [ -nocc ] [ -nofc ]
# usage() {
#   echo "Usage: $0 <submissions_dir> <target_dir> <tests_dir> <answers_dir> [-v] [-noexecute] [-nolc] [-nocc] [-nofc]"
#   exit 1
# }

# # 2. Ensure minimum arguments
# if [ $# -lt 4 ]; then
#   echo "Error: too few arguments."
#   usage
# fi

# # 3. Mandatory arguments
# SUBM_DIR="$1"      # submissions folder
# TARGET_DIR="$2"    # where we'll build targets/
# TEST_DIR="$3"      # tests/
# ANS_DIR="$4"       # answers/

# shift 4  # remove those from $@

# # 4. Default optional flags
# VERBOSE=false
# NOEXECUTE=false
# CALC_LC=true
# CALC_CC=true
# CALC_FC=true

# # Parse any remaining flags
# for arg in "$@"; do
#   case "$arg" in
#     -v)            VERBOSE=true ;;
#     -noexecute)    NOEXECUTE=true ;;
#     -nolc)         CALC_LC=false ;;
#     -nocc)         CALC_CC=false ;;
#     -nofc)         CALC_FC=false ;;
#     *) echo "Unknown option: $arg"; usage ;;
#   esac
# done

# # Debug print if verbose
# if [ "$VERBOSE" = true ]; then
#   echo ">> submissions: $SUBM_DIR"
#   echo ">> targets:     $TARGET_DIR"
#   echo ">> tests:       $TEST_DIR"
#   echo ">> answers:     $ANS_DIR"
#   echo ">> verbose      $VERBOSE"
#   echo ">> noexecute    $NOEXECUTE"
#   echo ">> calc_lc      $CALC_LC"
#   echo ">> calc_cc      $CALC_CC"
#   echo ">> calc_fc      $CALC_FC"
# fi

# # (Next: Task A – create target dirs & unzip + organize codes)
# # === Task A (improved) ===

# # 1. Create language folders
# mkdir -p "$TARGET_DIR"/{C,C++,Python,Java}

# # 2. For each submission ZIP
# for zipfile in "$SUBM_DIR"/*.zip; do
#   [ -e "$zipfile" ] || { echo "No .zip files in $SUBM_DIR"; break; }

#   filename=$(basename "$zipfile")
#   student_name="${filename%%_*}"
#   student_id="${filename##*_}"
#   student_id="${student_id%.zip}"

#   $VERBOSE && echo "Processing $student_name ($student_id)..."

#   # 3. Unzip into a fresh temp dir
#   tmpdir=$(mktemp -d) || exit 1
#   unzip -q "$zipfile" -d "$tmpdir"

#   # 4. Recursively find the one code file (any depth)
#   #    Sort so it’s deterministic, then take the first match.
#   codefile=$(find "$tmpdir" -type f \
#     \( -iname '*.c' -o -iname '*.cpp' -o -iname '*.java' -o -iname '*.py' \) \
#     | sort | head -n1)

#   if [ -z "$codefile" ]; then
#     echo "WARNING: no code file in $filename"
#     rm -rf "$tmpdir"
#     continue
#   fi
#   $VERBOSE && echo " Found: $codefile"

#   # 5. Map extension → folder & rename
#   case "${codefile,,}" in
#     *.c)      lang="C";    target_name="main.c"   ;;
#     *.cpp)    lang="C++";  target_name="main.cpp" ;;
#     *.java)   lang="Java"; target_name="Main.java";;
#     *.py)     lang="Python"; target_name="main.py";;
#   esac

#   # 6. Copy into targets
#   dest="$TARGET_DIR/$lang/$student_id"
#   mkdir -p "$dest"
#   cp "$codefile" "$dest/$target_name"
#   $VERBOSE && echo " -> $dest/$target_name"

#   rm -rf "$tmpdir"
# done

# # === Task B.0: Prepare CSV header ===

# header="student_id,student_name,language"
# [ "$NOEXECUTE" != true ] && header+=",matched,not_matched"
# $CALC_LC  && header+=",line_count"
# $CALC_CC  && header+=",comment_count"
# $CALC_FC  && header+=",function_count"

# echo "$header" > "$TARGET_DIR/result.csv"

# # === Task B.1: Code metrics ===
# source_file="$dest/$target_name"

# # 1) Line count
# if [ "$CALC_LC" = true ]; then
#   # wc -l outputs “  <num>”, so strip whitespace
#   lc=$(wc -l < "$source_file" | tr -d '[:space:]')
# else
#   lc=""
# fi

# # 2) Comment count
# if [ "$CALC_CC" = true ]; then
#   if [ "$lang" = "Python" ]; then
#     # Lines that start (possibly after spaces) with #
#     cc=$(grep -c '^[[:space:]]*#' "$source_file")
#   else
#     # C/C++/Java: lines that start (possibly after spaces) with //
#     cc=$(grep -c '^[[:space:]]*//' "$source_file")
#   fi
# else
#   cc=""
# fi

# # 3) (Bonus) Function count
# if [ "$CALC_FC" = true ]; then
#   case "$lang" in
#     C|C++)
#       # crude: return_type name(params) {
#       fc=$(grep -E '^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]*\([^)]*\)[[:space:]]*\{' \
#                "$source_file" | wc -l)
#       ;;
#     Java)
#       # naive: [modifier] returnType name(params) {
#       fc=$(grep -E '^[[:space:]]*(public|private|protected)?[[:space:]]*.+\(.*\)[[:space:]]*\{' \
#                "$source_file" | wc -l)
#       ;;
#     Python)
#       # def function_name(…
#       fc=$(grep -c '^[[:space:]]*def ' "$source_file")
#       ;;
#   esac
# else
#   fc=""
# fi

# # If verbose, echo what we found
# if [ "$VERBOSE" = true ]; then
#   echo " Metrics → lines:$lc comments:$cc functions:$fc"
# fi

# # === Task C: Compile, Run & Match ===
# matched=0
# not_matched=0

# if [ "$NOEXECUTE" = false ]; then
#   $VERBOSE && echo " Compiling & running tests…"

#   # 1) Compile or set execute command
#   case "$lang" in
#     C)
#       gcc "$source_file" -o "$dest/main.out"
#       exe="$dest/main.out"
#       ;;
#     "C++")
#       g++ "$source_file" -o "$dest/main.out"
#       exe="$dest/main.out"
#       ;;
#     Java)
#       # compile into the same directory
#       javac -d "$dest" "$dest/Main.java"
#       exe="java -cp $dest Main"
#       ;;
#     Python)
#       exe="python3 $dest/main.py"
#       ;;
#   esac

#   # 2) Loop over each test input
#   for testfile in "$TEST_DIR"/test*.txt; do
#     # Extract index: test3.txt → 3
#     testname=$(basename "$testfile")
#     idx="${testname#test}"
#     idx="${idx%.txt}"

#     outfile="$dest/out${idx}.txt"
#     $VERBOSE && echo "  Running test #$idx → $outfile"

#     # Run the program, redirecting stdin/stdout
#     if [ "$lang" = "Java" ]; then
#       # Need to cd into $dest for Java
#       (cd "$dest" && java Main < "$testfile" > "out${idx}.txt")
#     else
#       $exe < "$testfile" > "$outfile"
#     fi

#     # 3) Compare with the answer
#     ansfile="$ANS_DIR/ans${idx}.txt"
#     if diff -q "$outfile" "$ansfile" > /dev/null; then
#       matched=$((matched + 1))
#     else
#       not_matched=$((not_matched + 1))
#     fi
#   done
#   $VERBOSE && echo "  → matched: $matched, not matched: $not_matched"
# fi

# # === Task C.1: Append to CSV ===
# # Build the CSV row in exactly the header order
# # Start with: student_id,student_name,language
# row="$student_id,\"$student_name\",$lang"

# # If tests were run, add matched/not_matched
# if [ "$NOEXECUTE" = false ]; then
#   row+=",$matched,$not_matched"
# fi

# # Add metrics as per flags
# if [ "$CALC_LC" = true ]; then row+=",$lc";       fi
# if [ "$CALC_CC" = true ]; then row+=",$cc";       fi
# if [ "$CALC_FC" = true ]; then row+=",$fc";       fi

# # Append the row
# echo "$row" >> "$TARGET_DIR/result.csv"


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

# 4. Debug print if verbose
if [ "$VERBOSE" = true ]; then
  echo ">> submissions: $SUBM_DIR"
  echo ">> targets:     $TARGET_DIR"
  echo ">> tests:       $TEST_DIR"
  echo ">> answers:     $ANS_DIR"
  echo ">> verbose:     $VERBOSE"
  echo ">> noexecute:   $NOEXECUTE"
  echo ">> calc_lc:     $CALC_LC"
  echo ">> calc_cc:     $CALC_CC"
  echo ">> calc_fc:     $CALC_FC"
fi

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

  $VERBOSE && echo
  $VERBOSE && echo "=== Processing $student_name ($student_id) ==="

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
  $VERBOSE && echo " Found code: $codefile"

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
  $VERBOSE && echo " Copied → $dest/$target_name"

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
      cc=$(grep -c '^[[:space:]]*#' "$source_file")
    else
      cc=$(grep -c '^[[:space:]]*//' "$source_file")
    fi
  else
    cc=""
  fi

  if [ "$CALC_FC" = true ]; then
    case "$lang" in
      C|C++)
        fc=$(grep -E '^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]*\([^)]*\)[[:space:]]*\{' \
             "$source_file" | wc -l)
        ;;
      Java)
        fc=$(grep -E '^[[:space:]]*(public|private|protected)?[[:space:]]*.+\(.*\)[[:space:]]*\{' \
             "$source_file" | wc -l)
        ;;
      Python)
        fc=$(grep -c '^[[:space:]]*def ' "$source_file")
        ;;
    esac
  else
    fc=""
  fi

  $VERBOSE && echo " Metrics → lines:$lc  comments:$cc  functions:$fc"

  #
  # 7.f Task C: compile, run tests, diff
  #
  matched=0
  not_matched=0

  if [ "$NOEXECUTE" = false ]; then
    $VERBOSE && echo " Compiling & running tests…"

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

      $VERBOSE && echo "  Test #$idx → $outfile"
      $exe < "$testfile" > "$outfile"

      ansfile="$ANS_DIR/ans${idx}.txt"
      if diff -q "$outfile" "$ansfile" > /dev/null; then
        matched=$((matched+1))
      else
        not_matched=$((not_matched+1))
      fi
    done

    $VERBOSE && echo "  Results → matched:$matched  not_matched:$not_matched"
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
