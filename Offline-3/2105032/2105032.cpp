#include <chrono>
#include <fstream>
#include <iostream>
#include <pthread.h>
#include <semaphore.h>
#include <random>
#include <unistd.h>
#include <vector>
using namespace std;

#define POSSION_LAMBDA 20.0
#define OPERATIVE_MULTIPLIER 1000
#define STAFF_MULTIPLIER 200
#define STAFF_READ_MULTIPLIER 1000
#define CIH_TIME 1250
#define EXTRA_LOGGING 1
#define LOCKING_LOGGING 1

#define mutexLock pthread_mutex_lock
#define mutexUnlock pthread_mutex_unlock
#define newThread pthread_create
#define joinThread pthread_join
#define semWait sem_wait
#define semPost sem_post
#define semInit sem_init
#define semDestroy sem_destroy
#define eb emplace_back
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

int N, M, x, y;
int stationCnt = 4;

// # reader-writer part --- Task 2
int numStaffs = 2;
int readCnt = 0;
int completedTasks = 0;
pMutex sharedLock;         // Mutex lock for read count
pMutex completedTasksLock; // Mutex lock for completed tasks

semaPhore writerQ, readerQ;
bool isWriting = false;
int waitingReaders = 0, waitingWriters = 0;

vector<semaPhore> stationSemaphores; // Semaphore for each station
vector<semaPhore> groupSemaphores;
pMutex outputLock;

// # Operative class --- Task 1
class Operative
{
public:
    int identifier;
    int unitNum;
    int stationNum;
    bool isLeader;

    Operative(int id)
    {
        this->identifier = id;
        this->unitNum = (id - 1) / M + 1;
        this->stationNum = (id % 4) + 1;
        this->isLeader = (id % M == 0);
    }

    void printDetails()
    {
        cout << "Operative ID: " << identifier
             << ", Unit Number: " << unitNum
             << ", Station Number: " << stationNum
             << ", Is Leader: " << (isLeader ? "Yes" : "No") << endl;
    }
};
vector<Operative> operatives;
void writeOutput(string);

// # Intelligent Staff class --- Task 2
class IntelligentStaff
{
public:
    int id;

    IntelligentStaff(int id) : id(id) {}
};
vector<IntelligentStaff> staffs;

void readerLock()
{
    mutexLock(&sharedLock);

    waitingReaders++;
    if (isWriting)
    {
        mutexUnlock(&sharedLock);
        semWait(&readerQ);
        mutexLock(&sharedLock);
    }

    // wait shesh, ekhn lock dibo
    readCnt++;
    waitingReaders--;
    // signal other readers if any, allowing them to access simultaneously
    if(LOCKING_LOGGING)
        writeOutput("Reader lock acquired. Current read count: " + to_string(readCnt) + ", Waiting readers: " + to_string(waitingReaders)+ ", Waiting writers: " + to_string(waitingWriters));
    if (waitingReaders > 0 && !isWriting)
    {
        semPost(&readerQ);
    }

    mutexUnlock(&sharedLock);
}

void readerUnlock()
{
    mutexLock(&sharedLock);

    readCnt--;
    if(LOCKING_LOGGING)
        writeOutput("Reader lock released. Current read count: " + to_string(readCnt) + ", Waiting readers: " + to_string(waitingReaders) + ", Waiting writers: " + to_string(waitingWriters));

    if (readCnt == 0 && waitingWriters > 0)
    {
        semPost(&writerQ); // no readers left, but waiting writers, so allow them in writer Q
    }

    mutexUnlock(&sharedLock);
}

void writerLock()
{
    mutexLock(&sharedLock);

    waitingWriters++;

    // some are reading or already another writer is writing
    // wait them
    if (readCnt > 0 || isWriting)
    {
        mutexUnlock(&sharedLock);
        semWait(&writerQ);
        mutexLock(&sharedLock);
    }
    isWriting = true;
    waitingWriters--;
    if(LOCKING_LOGGING)
        writeOutput("Writer lock acquired. Waiting writers: " + to_string(waitingWriters)+ ", Waiting readers: " + to_string(waitingReaders)+ ", Current read count: " + to_string(readCnt));

    // no extra condition so we are not prioritizing writers over readers

    mutexUnlock(&sharedLock);
}

void writerUnlock()
{
    mutexLock(&sharedLock);

    isWriting = false;
    if(LOCKING_LOGGING)
        writeOutput("Writer lock released. Waiting readers: " + to_string(waitingReaders) + ", Waiting writers: " + to_string(waitingWriters)+ ", Current read count: " + to_string(readCnt));
    if (waitingReaders > 0)
    {
        semPost(&readerQ);
    }
    else if (waitingWriters > 0)
    {
        semPost(&writerQ);
    }

    mutexUnlock(&sharedLock);
}

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
}

void initWriteSemaphore()
{
    semInit(&writerQ, 0, 0);
}

void intiReaderSemaphore()
{
    semInit(&readerQ, 0, 0);
}

// uses mutex lock to write output to avoid interleaving
void writeOutput(string output)
{
    mutexLock(&outputLock);
    cout << output << endl;
    // usleep(10000); // Sleep for 1 ms to simulate some delay in output
    mutexUnlock(&outputLock);
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

    startTime = chrono::high_resolution_clock::now();
}

void *intelligentStaffsWork(void *arg)
{
    IntelligentStaff *staff = (IntelligentStaff *)arg;

    while (true)
    {
        usleep(STAFF_MULTIPLIER * getRandomNumber());
        readerLock();
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

    writeOutput("Operative " + to_string(operative->identifier) + UNIT + LEADER + " has arrived at typewriting station " + TS + "at time " + to_string(getTime()));

    semWait(&stationSemaphores[operative->stationNum - 1]);
    usleep(x * 1000);
    writeOutput("Operative " + to_string(operative->identifier) + UNIT + LEADER + " has completed document recreation " + TS + "at time " + to_string(getTime()));
    semPost(&stationSemaphores[operative->stationNum - 1]);

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

        writerLock();

        // ! ekhn shob operative e kaaj kore felse, so logbook e write kora jabe
        writeOutput("Unit " + to_string(operative->unitNum) + " has completed document recreation phase at time " + to_string(getTime()));

        usleep(y * 1000); // y milliseconds
        mutexLock(&completedTasksLock);

        completedTasks++;

        mutexUnlock(&completedTasksLock);

        writeOutput("Unit " + to_string(operative->unitNum) + " has completed intelligence distribution at time " + to_string(getTime()));

        writerUnlock();
    }

    return NULL;
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
}

int main(int argc, char *argv[])
{
    if (argc != 3)
    {
        cerr << "Usage: ./a.out <input_file> <output_file>" << endl;
        return 0;
    }

    // check for intput file existence
    if (!ifstream(argv[1]))
    {
        cerr << "Error: Input file does not exist." << endl;
        return 1;
    }

    // File handling for input and output redirection
    ifstream inputFile(argv[1]);
    streambuf *cinBuffer = cin.rdbuf(); // Save original cin buffer
    cin.rdbuf(inputFile.rdbuf());       // Redirect cin to input file

    ofstream outputFile(argv[2]);
    streambuf *coutBuffer = cout.rdbuf(); // Save original cout buffer
    cout.rdbuf(outputFile.rdbuf());       // Redirect cout to output file

    cin >> N >> M;
    cin >> x >> y;

    if (N % M != 0)
    {
        cin.rdbuf(cinBuffer);
        cout.rdbuf(coutBuffer);
        cerr << "Error: N must be divisible by M." << endl;
        return 1;
    }

    // cout << "N: " << N << ", M: " << M << endl;
    // cout << "x: " << x << ", y: " << y << endl;

    // for(int i=1;i<=N;i++)
    // {
    //     operatives.push_back(Operative(i)); // Create and add Operative objects to the vector
    // }

    // for(Operative &o : operatives)
    // {
    //     o.printDetails(); // Print details of each operative
    // }

    pthread_t operativesThreads[N];

    initialize();

    for (int i = 0; i < N; i++)
    {
        newThread(&operativesThreads[i], NULL, operativesWork, &operatives[i]);
    }
    pthread_t staffsThreads[numStaffs];

    for (int i = 0; i < numStaffs; i++)
    {
        newThread(&staffsThreads[i], NULL, intelligentStaffsWork, (void *)&staffs[i]);
    }

    for (int i = 0; i < N; i++)
    {
        joinThread(operativesThreads[i], NULL);
    }

    for (int i = 0; i < numStaffs; i++)
    {
        joinThread(staffsThreads[i], NULL);
    }

    cleanup();

    // Restore cin and cout to their original states (console)
    cin.rdbuf(cinBuffer);
    cout.rdbuf(coutBuffer);

    return 0;
}