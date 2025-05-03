#!/usr/bin/env bash

# organize_explained.sh - A script to organize, analyze, and evaluate student code submissions
# --------------------------------------------------------------------------------------
#
# This script processes a directory of student code submissions (as zip files),
# organizes them by programming language, analyzes code metrics, and optionally
# tests the code against provided test cases.
#
# USAGE:
#   ./organize.sh <submissions_dir> <target_dir> <tests_dir> <answers_dir> [options]
#
# REQUIRED ARGUMENTS:
#   <submissions_dir> - Directory containing student submission zip files
#                       Format expected: studentname_studentid.zip
#   <target_dir>      - Directory where organized files and results will be stored
#   <tests_dir>       - Directory containing test input files (test1.txt, test2.txt, etc.)
#   <answers_dir>     - Directory containing expected output files (ans1.txt, ans2.txt, etc.)
#
# OPTIONS:
#   -v          - Enable verbose output
#   -noexecute  - Skip code execution and testing
#   -nolc       - Skip line count calculation
#   -nocc       - Skip comment count calculation
#   -nofc       - Skip function count calculation
#
# WORKFLOW:
#   1. Create language-specific subdirectories in target directory
#   2. For each student submission ZIP file:
#      a. Extract student name and ID from filename
#      b. Unzip submission to a temporary directory
#      c. Identify the programming language (C, C++, Java, Python)
#      d. Copy the source file to the appropriate language directory
#      e. Calculate code metrics (if enabled):
#         - Line count
#         - Comment count
#         - Function count
#      f. Execute code against test cases (if -noexecute is not set):
#         - Compile code (if needed)
#         - Run each test input and compare with expected output
#      g. Record results in CSV file
#
# OUTPUT:
#   - Organized code files in <target_dir>/{C,C++,Python,Java}/<student_id>/
#   - Results in <target_dir>/result.csv with the following columns:
#     * student_id
#     * student_name
#     * language
#     * matched (number of tests passed) [if -noexecute is not used]
#     * not_matched (number of tests failed) [if -noexecute is not used]
#     * line_count [if -nolc is not used]
#     * comment_count [if -nocc is not used]
#     * function_count [if -nofc is not used]
#
# REQUIREMENTS:
#   - unzip
#   - gcc (for C files)
#   - g++ (for C++ files)
#   - javac/java (for Java files)
#   - python3 (for Python files)

# Function to display usage information and exit
usage() {
  echo "Usage: $0 <submissions_dir> <target_dir> <tests_dir> <answers_dir> [-v] [-noexecute] [-nolc] [-nocc] [-nofc]"
  exit 1
}

# Check mandatory args
if [ $# -lt 4 ]; then
  echo "Error: too few arguments."
  usage
fi

# Assign the required directories to variables
SUBM_DIR="$1"      # submissions folder
TARGET_DIR="$2"    # where we'll build targets/
TEST_DIR="$3"      # tests/
ANS_DIR="$4"       # answers/

# Remove the first 4 arguments from the arguments list,
# leaving only the optional flags for processing
shift 4 

# Set default values for optional flags
VERBOSE=false
NOEXECUTE=false
CALC_LC=true
CALC_CC=true
CALC_FC=true

# Process each optional argument using a case statement
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
    *) # Base case - handle unknown options
      echo "Unknown option: $optional_arg"; 
        usage 
      ;;
  esac
done

### ===Task A: Organize===
# Create necessary directory structure for organizing files by language
mkdir -p "$TARGET_DIR"/{C,C++,Python,Java}

# Create the CSV header line based on enabled features
header="student_id,student_name,language"
if [ "$NOEXECUTE" != true ]; then
  header+=",matched,not_matched"
fi
# Conditionally add headers using logical operators:
# If CALC_LC is true, it adds ",line_count" to the header
$CALC_LC && header+=",line_count"
$CALC_CC && header+=",comment_count"
$CALC_FC && header+=",function_count"
echo "$header" > "$TARGET_DIR/result.csv"

# Process each student ZIP file in the submissions directory
for zipfile in "$SUBM_DIR"/*.zip; do
  # Check if any zip files exist - if not, display message and break loop
  [ -e "$zipfile" ] || { echo "No .zip files in $SUBM_DIR"; break; }

  # Extract student information from filename
  filename=$(basename "$zipfile")
  # Extract student name using parameter expansion:
  # %%_* means "remove the longest match of _* from the end"
  # This removes everything from the first underscore to the end
  student_name="${filename%%_*}" 
  
  # Extract student ID using parameter expansion:
  # ##*_ means "remove the longest match of *_ from the beginning"
  # This removes everything from the beginning up to the last underscore
  student_id="${filename##*_}" 
  
  # Remove .zip extension from student ID
  # % is parameter expansion that removes the shortest matching pattern from the end
  student_id="${student_id%.zip}" 

  $VERBOSE && echo "Processing files of $student_id"

  # Create a temporary directory for extracting the zip
  # mktemp -d creates a unique temporary directory and returns its path
  tmpdir=$(mktemp -d) || { echo "ERROR: cannot create temp dir"; exit 1; }
  
  # Extract the zip contents quietly (-q) to the temporary directory
  unzip -q "$zipfile" -d "$tmpdir"

  # Find the first code file in the submission using a complex find command
  # This searches for files with extensions .c, .cpp, .java, or .py
  # The search is case-insensitive (-iname) and recursive
  # Results are sorted and only the first match is taken (head -n1)
  codefile=$(find "$tmpdir" -type f \
    \( -iname '*.c' -o -iname '*.cpp' -o -iname '*.java' -o -iname '*.py' \) \
    | sort | head -n1)

  # Skip submissions with no code files
  if [ -z "$codefile" ]; then
    echo "WARNING: no code file in $filename"
    rm -rf "$tmpdir"
    continue
  fi

  # Determine the programming language and target filename
  # The ",," converts the filename to lowercase for case-insensitive matching
  case "${codefile,,}" in
    *.c)    lang="C";     target_name="main.c"   ;;
    *.cpp)  lang="C++";   target_name="main.cpp" ;;
    *.java) lang="Java";  target_name="Main.java";;
    *.py)   lang="Python";target_name="main.py";;
  esac

  # Create destination directory and copy the source file
  dest="$TARGET_DIR/$lang/$student_id"
  mkdir -p "$dest"
  cp "$codefile" "$dest/$target_name"

  # Clean up temporary directory
  rm -rf "$tmpdir"

  ### ===Task B: Code Analysis===
  source_file="$dest/$target_name"

  # Calculate line count if enabled
  if [ "$CALC_LC" = true ]; then
    # Count lines and trim whitespace from the result
    lc=$(wc -l < "$source_file" | tr -d '[:space:]')
  else
    lc=""
  fi

  # Calculate comment count if enabled
  if [ "$CALC_CC" = true ]; then
    # This complex sed command first removes string literals to avoid counting comments in strings
    # 1. s/"([^"\\]|\\.)*"//g: Remove double-quoted strings
    # 2. s/'([^'\\]|\\.)*'//g: Remove single-quoted strings
    # Then grep counts comment markers (# for Python, // for other languages)
    if [ "$lang" = "Python" ]; then
      cc=$(sed -E 's/"([^"\\]|\\.)*"//g; s/'"'"'([^'"'"'\]|\\.)*'"'"'//g' "$source_file" | grep -c '#')
    else
      cc=$(sed -E 's/"([^"\\]|\\.)*"//g; s/'"'"'([^'"'"'\]|\\.)*'"'"'//g' "$source_file" | grep -c '//')
    fi
  else
    cc=""
  fi

  # Calculate function count if enabled
  if [ "$CALC_FC" = true ]; then
    case "$lang" in
      C|C++)
          # Match C/C++ function definitions like: 
          # return_type function_name(parameters) {
          fc=$(grep -E '^[[:space:]]*[A-Za-z_][A-Za-z0-9_]+[[:space:]]+[A-Za-z_][A-Za-z0-9_]+[[:space:]]*\([^)]*\)[[:space:]]*\{' "$source_file" | wc -l)
        ;;
      Java)
          # Match Java method definitions (more complex due to modifiers, generics)
          fc=$(grep -E '^[[:space:]]*([A-Za-z_$][A-Za-z0-9_$<>]*[[:space:]]+)+[A-Za-z_$][A-Za-z0-9_$]*[[:space:]]*\([^)]*\)[[:space:]]*\{' "$source_file" | wc -l)
        ;;
      Python)
          # Count Python function definitions (def keyword)
          fc=$(grep -c '^[[:space:]]*def ' "$source_file")
        ;;
    esac
  else
    fc=""
  fi

  ### ===Task C: Execute and Match===
  matched=0
  not_matched=0

  if [ "$NOEXECUTE" = false ]; then
    $VERBOSE && echo "Executing files of $student_id"

    # Compile code (if needed) and set the execution command
    case "$lang" in
      C)
          # Compile C code with gcc
          gcc "$source_file" -o "$dest/main.out"
          exe="$dest/main.out"
        ;;
      "C++")
          # Compile C++ code with g++
          g++ "$source_file" -o "$dest/main.out"
          exe="$dest/main.out"
        ;;
      Java)
          # Compile Java code and set execution command with classpath
          javac -d "$dest" "$dest/Main.java"
          exe="java -cp $dest Main"
        ;;
      Python)
          # No compilation needed for Python
          exe="python3 $dest/main.py"
        ;;
    esac

    # Run each test case and compare with expected output
    for testfile in "$TEST_DIR"/test*.txt; do
      # Extract test number from filename using parameter expansion:
      # Remove "test" prefix and ".txt" suffix to get the test index
      testname=$(basename "$testfile")
      idx="${testname#test}"  # Remove prefix "test"
      idx="${idx%.txt}"       # Remove suffix ".txt"
      outfile="$dest/out${idx}.txt"

      # Execute the program with test input and capture output
      $exe < "$testfile" > "$outfile"

      # Compare output with expected answer
      ansfile="$ANS_DIR/ans${idx}.txt"
      # /dev/null suppresses output of diff command
      if diff -q "$outfile" "$ansfile" > /dev/null; then
        matched=$((matched+1))
      else
        not_matched=$((not_matched+1))
      fi
    done
  fi

  # Build CSV row for this student with all collected metrics
  row="$student_id,\"$student_name\",$lang"
  # Add execution results only if execute is enabled
  [ "$NOEXECUTE" = false ] && row+=",${matched},${not_matched}"
  # Add metrics conditionally based on enabled flags
  [ "$CALC_LC" = true ] && row+=",${lc}"
  [ "$CALC_CC" = true ] && row+=",${cc}"
  [ "$CALC_FC" = true ] && row+=",${fc}"
  echo "$row" >> "$TARGET_DIR/result.csv"
done

$VERBOSE && echo "All submissions processed successfully."