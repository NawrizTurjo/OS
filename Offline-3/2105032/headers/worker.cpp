#pragma once
#include "util.cpp"
#include "globalVariables.cpp"
#include "classes.cpp"
#include "readerWriter.cpp"
#include "notification.cpp"

// uses mutex lock to write output to avoid interleaving
void writeOutput(string output)
{
    mutexLock(&outputLock);
    cout << output << endl;
    // usleep(10000); // Sleep for 1 ms to simulate some delay in output
    mutexUnlock(&outputLock);
}

void *intelligentStaffsWork(void *arg)
{
    IntelligentStaff *staff = (IntelligentStaff *)arg;

    while (true)
    {
        usleep(STAFF_MULTIPLIER * getRandomNumber());
        readerLock();
        if (LOGGING)
            writeOutput("Intelligence Staff " + to_string(staff->id) + " began reviewing logbook at time " + to_string(getTime()) + ". Operations completed = " + to_string(completedTasks));
        usleep(STAFF_READ_MULTIPLIER * getRandomNumber());
        readerUnlock();

        if (completedTasks >= N / M)
        {
            // usleep(getRandomNumber() * 10000);
            break;
        }
    }
    return NULL;
}

void *operativesWork(void *arg)
{
    Operative *operative = (Operative *)arg;

    // Debugging strings
    string TS = "";
    string UNIT = "";
    string LEADER = "";
    if (EXTRA_LOGGING)
    {
        TS = "(TS" + to_string(operative->stationNum) + ") ";
        UNIT = " (Unit " + to_string(operative->unitNum) + ")";
        LEADER = (operative->isLeader) ? " (Leader)" : "";
    }

    // Arrival at random time
    usleep(getRandomNumber() * OPERATIVE_MULTIPLIER);

    if (LOGGING)
        writeOutput("Operative " + to_string(operative->identifier) + UNIT + LEADER + " has arrived at typewriting station " + TS + "at time " + to_string(getTime()));

    // semWait(&stationSemaphores[operative->stationNum - 1]);
    stationLock(operative, TS, UNIT, LEADER);
    usleep(x * 1000);
    if (LOGGING)
        writeOutput("Operative " + to_string(operative->identifier) + UNIT + LEADER + " has completed document recreation " + TS + "at time " + to_string(getTime()));
    stationUnlock(operative, TS);
    // semPost(&stationSemaphores[operative->stationNum - 1]);

    // # Leader part
    semPost(&groupSemaphores[operative->unitNum - 1]); // Signal the group semaphore
    // usleep(CIH_TIME);                                   // some delay to simulate the time to go to the TS to CIH

    // # This portion will be written into the logbook, so we need reader-writer locks
    if (operative->isLeader)
    {
        for (int i = 0; i < M; i++)
        {
            sem_wait(&groupSemaphores[operative->unitNum - 1]);
        }

        // ! ekhn shob operative e kaaj kore felse, so logbook e write kora jabe
        if (LOGGING)
            writeOutput("Unit " + to_string(operative->unitNum) + " has completed document recreation phase at time " + to_string(getTime()));
        
        writerLock();

        if(EXTRA_LOGGING)
            writeOutput("<CIH> Unit " + to_string(operative->unitNum) + " is arrived at Central Intelligence Hub at time " + to_string(getTime()));
        
        usleep(y * 1000); // y milliseconds
        // mutexLock(&completedTasksLock);

        completedTasks++;

        // mutexUnlock(&completedTasksLock);

        if (LOGGING)
            writeOutput("Unit " + to_string(operative->unitNum) + " has completed intelligence distribution at time " + to_string(getTime()));

        writerUnlock();
    }

    return NULL;
}
