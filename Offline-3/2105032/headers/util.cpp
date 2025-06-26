#pragma once
#include <chrono>
#include <fstream>
#include <iostream>
#include <pthread.h>
#include <semaphore.h>
#include <random>
#include <unistd.h>
#include <vector>
#include <algorithm>
using namespace std;

#define POSSION_LAMBDA 20.0
#define OPERATIVE_MULTIPLIER 1000
#define STAFF_MULTIPLIER 200
#define STAFF_READ_MULTIPLIER 1000
#define CIH_TIME 1250
#define LOGGING 1
#define EXTRA_LOGGING 1
#define LOCKING_LOGGING 1
#define NOTIFICATION_LOGGING 1

#define mutexLock pthread_mutex_lock
#define mutexUnlock pthread_mutex_unlock
#define newThread pthread_create
#define joinThread pthread_join
#define semWait sem_wait
#define semPost sem_post
#define semInit sem_init
#define semDestroy sem_destroy
#define eb emplace_back
#define pb pop_back
#define semaPhore sem_t
#define pThread pthread_t
#define pMutex pthread_mutex_t
#define mutexInit pthread_mutex_init
#define mutexDestroy pthread_mutex_destroy

// Timing functions
auto startTime = chrono::high_resolution_clock::now();

long long getTime()
{
    auto endTime = chrono::high_resolution_clock::now();
    auto duration = chrono::duration_cast<chrono::milliseconds>(
        endTime - startTime);
    long long elapsedTimeMs = duration.count();
    return elapsedTimeMs;
}

// Function to generate a Poisson-distributed random number
int getRandomNumber()
{
    random_device rd;
    mt19937 generator(rd());

    // Lambda value for the Poisson distribution
    double lambda = POSSION_LAMBDA;
    poisson_distribution<int> poissonDist(lambda);
    return poissonDist(generator);
}

void writeOutput(string);