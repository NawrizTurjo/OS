# CSE 314: Operating Systems

This repository contains the implementation of three key assignments for the Operating Systems course, each focusing on different aspects of OS concepts and systems programming.

## Assignments Overview

### Offline-1: Bash Scripting for Automated File Organization

A Bash script implementation that automates file organization, analysis, and testing for student code submissions. Key features include:

- Organizing student submissions into language-specific directories
- Calculating code metrics:
  - Line count
  - Comment count
  - Function count
- Executing student code against test cases
- Generating detailed reports in CSV format

**Technologies:** Bash, regex, file manipulation utilities

### Offline-2: XV6 Operating System Modifications

Implementation of scheduling algorithms and system calls in the XV6 educational operating system:

- Lottery Scheduler implementation
  - Random ticket-based process selection
  - Process priority management
- MLFQ Scheduler implementation
- New system calls:
  - `history`: Command history tracking and retrieval
  - `settickets`: Set process lottery tickets
  - `getpinfo`: Get process information

**Technologies:** C, XV6, UNIX system programming

### Offline-3: IPC Implementation with Semaphores

A multithreaded program simulating a "Peaky Blinders" inspired document processing system, implementing:

- Reader-Writer problem with reader priority
- Complex synchronization between multiple thread groups
- Proper semaphore and mutex usage for resource sharing
- Thread coordination for sequential task execution

**Technologies:** C++, POSIX threads, semaphores, mutexes

## Repository Structure

```
.
├── Offline-1
│   ├── Workspace      # Shell scripts for file organization
│   └── ...            # Test files and examples
│
├── Offline-2
│   ├── 2105032.patch  # XV6 modifications patch
│   └── spec           # Assignment specifications
│
└── Offline-3
    ├── 2105032        # IPC implementation files
    │   ├── 2105032_together.cpp
    │   └── run-script.sh
    └── spec           # Assignment specifications
```

## Setup and Usage

Each assignment includes specific instructions for compilation and execution:

### Offline-1
```bash
cd Offline-1/Workspace
./organize.sh <submissions_dir> <target_dir> <tests_dir> <answers_dir> [options]
```

### Offline-2
```bash
# Clone the XV6 repository
git clone https://github.com/mit-pdos/xv6-riscv
## for online use this instead: git clone https://github.com/shuaibw/xv6-riscv --depth=1
# Apply the patch to XV6
cd xv6-riscv  # XV6 source directory
git apply ../2105032.patch
make qemu
```

### Offline-3
```bash
cd Offline-3/2105032
./run-script.sh  # Compiles and runs with input/output files
```
