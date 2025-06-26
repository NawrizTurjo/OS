#pragma once
#include "util.cpp"

int N, M, x, y;
int stationCnt = 4;

// # reader-writer part --- Task 2
int numStaffs = 2;
int readCnt = 0;
int completedTasks = 0;
pMutex sharedLock; // Mutex lock for read count
// pMutex completedTasksLock; // Mutex lock for completed tasks

semaPhore writerQ, readerQ;
bool isWriting = false;
int waitingReaders = 0, waitingWriters = 0;

vector<semaPhore> stationSemaphores; // Semaphore for each station
vector<semaPhore> groupSemaphores;
pMutex outputLock;
vector<pMutex> stationVectorsLock;
vector<vector<int>> waitingAtStation;