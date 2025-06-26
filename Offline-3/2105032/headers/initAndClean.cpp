#pragma once
#include "util.cpp"
#include "globalVariables.cpp"
#include "classes.cpp"

void initStationSemaphores()
{
    for (int i = 0; i < stationCnt; i++)
    {
        semaPhore sem;
        semInit(&sem, 0, 1);
        stationSemaphores.eb(sem);
    }
}

void initGroupSemaphores()
{
    int groupCnt = N / M;
    for (int i = 0; i < groupCnt; i++)
    {
        semaPhore sem;
        semInit(&sem, 0, 0);
        groupSemaphores.eb(sem);
    }
}

void initMutex()
{
    mutexInit(&outputLock, NULL);
    mutexInit(&sharedLock, NULL);
    // mutexInit(&completedTasksLock, NULL);
}

void initWriteSemaphore()
{
    semInit(&writerQ, 0, 0);
}

void intiReaderSemaphore()
{
    semInit(&readerQ, 0, 0);
}

void initStationVectorsLock()
{
    for (int i = 0; i < stationCnt; i++)
    {
        pMutex mtx;
        mutexInit(&mtx, NULL);
        stationVectorsLock.eb(mtx);
    }
}

void initWaitingAtStation()
{
    for (int i = 0; i < stationCnt; i++)
    {
        // empty vector initially
        waitingAtStation.eb(vector<int>());
    }
}

void initialize()
{
    for (int i = 1; i <= N; i++)
    {
        operatives.eb(Operative(i));
    }

    for (int i = 0; i < numStaffs; i++)
    {
        staffs.eb(IntelligentStaff(i + 1));
    }

    initStationSemaphores();
    initGroupSemaphores();
    initMutex();
    initWriteSemaphore();
    intiReaderSemaphore();
    initWaitingAtStation();
    initStationVectorsLock();

    startTime = chrono::high_resolution_clock::now();
}

void cleanup()
{
    for (int i = 0; i < stationCnt; i++)
    {
        semDestroy(&stationSemaphores[i]);
    }

    for (int i = 0; i < N / M; i++)
    {
        semDestroy(&groupSemaphores[i]);
    }

    mutexDestroy(&outputLock);
    mutexDestroy(&sharedLock);
    semDestroy(&writerQ);
    semDestroy(&readerQ);

    for (int i = 0; i < stationCnt; i++)
    {
        mutexDestroy(&stationVectorsLock[i]);
    }
}