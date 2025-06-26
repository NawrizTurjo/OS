#pragma once
#include "util.cpp"
#include "globalVariables.cpp"
#include "classes.cpp"

void stationLock(Operative *operative, string TS, string UNIT, string LEADER)
{
    mutexLock(&stationVectorsLock[operative->stationNum - 1]);

    // initially make them wait at the waiting vector
    waitingAtStation[operative->stationNum - 1].eb(operative->identifier);

    mutexUnlock(&stationVectorsLock[operative->stationNum - 1]);

    semWait(&stationSemaphores[operative->stationNum - 1]);

    mutexLock(&stationVectorsLock[operative->stationNum - 1]);

    if (NOTIFICATION_LOGGING)
        writeOutput("<NOTIFICATION_" + to_string(operative->stationNum) + "> Operative " + to_string(operative->identifier) + UNIT + LEADER + " got access at typewriting station " + TS + "at time " + to_string(getTime()));
    vector<int> &v = waitingAtStation[operative->stationNum - 1];
    v.erase(remove(v.begin(), v.end(), operative->identifier), v.end());

    mutexUnlock(&stationVectorsLock[operative->stationNum - 1]);
}

void stationUnlock(Operative *operative, string TS)
{

    mutexLock(&stationVectorsLock[operative->stationNum - 1]);

    for (auto id : waitingAtStation[operative->stationNum - 1])
    {
        string TS = "(TS" + to_string(operative->stationNum) + ") ";
        int unitNum = (id - 1) / M + 1;
        int isLeader = (id % M == 0) ? 1 : 0;
        string UNIT = " (Unit " + to_string(unitNum) + ")";
        string LEADER = (isLeader) ? " (Leader)" : "";

        if (NOTIFICATION_LOGGING)
            writeOutput("<NOTIFICATION_" + to_string(operative->stationNum) + "> Operative " + to_string(id) + UNIT + LEADER + " is avaliable to work at typewriting station " + TS + "at time " + to_string(getTime()));
    }

    mutexUnlock(&stationVectorsLock[operative->stationNum - 1]);

    semPost(&stationSemaphores[operative->stationNum - 1]);
}