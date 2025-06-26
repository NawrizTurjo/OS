#pragma once
#include "util.cpp"
#include "globalVariables.cpp"

void readerLock()
{
    mutexLock(&sharedLock);

    waitingReaders++;
    while (isWriting)
    {
        mutexUnlock(&sharedLock);
        semWait(&readerQ); // (1)
        mutexLock(&sharedLock);
    }

    // wait shesh, ekhn lock dibo
    readCnt++;
    waitingReaders--;
    // signal other readers if any, allowing them to access simultaneously
    if (LOCKING_LOGGING)
        writeOutput("<READER_LOCK_A> Reader lock acquired. Current read count: " + to_string(readCnt) + ", Waiting readers: " + to_string(waitingReaders) + ", Waiting writers: " + to_string(waitingWriters));
    // if (waitingReaders > 0 && !isWriting)
    // {
    //     semPost(&readerQ);
    //     // (1) e jara ache tader ber korbe
    // }

    mutexUnlock(&sharedLock);
}

void readerUnlock()
{
    mutexLock(&sharedLock);

    readCnt--;
    if (LOCKING_LOGGING)
        writeOutput("<READER_LOCK_R> Reader lock released. Current read count: " + to_string(readCnt) + ", Waiting readers: " + to_string(waitingReaders) + ", Waiting writers: " + to_string(waitingWriters));

    if (readCnt == 0 && waitingWriters > 0)
    {
        semPost(&writerQ); // no readers left, but waiting writers, so allow them in writer Q
        // (2) e jara ache tader ber korbe
    }

    mutexUnlock(&sharedLock);
}

void writerLock()
{
    mutexLock(&sharedLock);

    waitingWriters++;

    // some are reading or already another writer is writing
    // wait them
    while (readCnt > 0 || isWriting)
    {
        mutexUnlock(&sharedLock);
        semWait(&writerQ); // (2)
        mutexLock(&sharedLock);
    }
    isWriting = true;
    waitingWriters--;
    if (LOCKING_LOGGING)
        writeOutput("<WRITER_LOCK_A> Writer lock acquired. Waiting writers: " + to_string(waitingWriters) + ", Waiting readers: " + to_string(waitingReaders) + ", Current read count: " + to_string(readCnt));

    // no extra condition so we are not prioritizing writers over readers

    mutexUnlock(&sharedLock);
}

void writerUnlock()
{
    mutexLock(&sharedLock);

    isWriting = false;
    if (LOCKING_LOGGING)
        writeOutput("<WRITER_LOCK_R> Writer lock released. Waiting readers: " + to_string(waitingReaders) + ", Waiting writers: " + to_string(waitingWriters) + ", Current read count: " + to_string(readCnt));
    if (waitingReaders > 0)
    {
        for (int i = 0; i < waitingReaders; i++)
            semPost(&readerQ); // (1) er readerQ theke waiting gulake aage nibe
    }
    else if (waitingWriters > 0)
    {
        semPost(&writerQ); // then (2) er waiting writer gulake ber korbe (if any)
    }

    mutexUnlock(&sharedLock);
}