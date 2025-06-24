#include <chrono>
#include <fstream>
#include <iostream>
#include <pthread.h>
#include <semaphore.h>
#include <random>
#include <unistd.h>
#include <vector>
using namespace std;

#define POSSION_LAMBDA 5.0
#define OPERATIVE_MULTIPLIER 1000
#define STAFF_MULTIPLIER 200
#define CIH_TIME 1250
#define EXTRA_LOGGING 1

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
auto startTime = std::chrono::high_resolution_clock::now();

long long getTime()
{
    auto endTime = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(
        endTime - startTime);
    long long elapsedTimeMs = duration.count();
    return elapsedTimeMs;
}

// Function to generate a Poisson-distributed random number
int getRandomNumber()
{
    std::random_device rd;
    std::mt19937 generator(rd());

    // Lambda value for the Poisson distribution
    double lambda = POSSION_LAMBDA;
    std::poisson_distribution<int> poissonDist(lambda);
    return poissonDist(generator);
}

int N, M, x, y;
int stationCnt = 4;

// # reader-writer part --- Task 2
int numStaffs = 2;
int readCnt = 0;
int completedTasks = 0;
pMutex readCntLock; // Mutex lock for read count
semaPhore writeSemaphore;

std::vector<semaPhore> stationSemaphores; // Semaphore for each station
std::vector<semaPhore> groupSemaphores;
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
        std::cout << "Operative ID: " << identifier
                  << ", Unit Number: " << unitNum
                  << ", Station Number: " << stationNum
                  << ", Is Leader: " << (isLeader ? "Yes" : "No") << std::endl;
    }
};
std::vector<Operative> operatives; 

// # Intelligent Staff class --- Task 2
class IntelligentStaff
{
public:
    int id;

    IntelligentStaff(int id) : id(id) {}
};
std::vector<IntelligentStaff> staffs; 

void readerLock()
{
    mutexLock(&readCntLock);

    readCnt++;
    if (readCnt == 1)
    {
        // This is the first reader, lock the writers
        semWait(&writeSemaphore);
    }

    mutexUnlock(&readCntLock);
}

void readerUnlock()
{
    mutexLock(&readCntLock);

    readCnt--;
    if (readCnt == 0)
    {
        // This is the last reader, unlock the writers
        semPost(&writeSemaphore);
    }

    mutexUnlock(&readCntLock);
}

void writerLock()
{
    // wait all other writers
    semWait(&writeSemaphore);
}

void writerUnlock()
{
    // signal as done
    semPost(&writeSemaphore);
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
    mutexInit(&readCntLock, NULL);
}

void initWriteSemaphore()
{
    semInit(&writeSemaphore, 0, 1);
}

// uses mutex lock to write output to avoid interleaving
void writeOutput(std::string output)
{
    mutexLock(&outputLock);
    std::cout << output << std::endl;
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

    startTime = std::chrono::high_resolution_clock::now();
}

void *intelligentStaffsWork(void *arg)
{
    IntelligentStaff *staff = (IntelligentStaff *)arg;

    while (completedTasks < N / M)
    {
        usleep(STAFF_MULTIPLIER * getRandomNumber());
        readerLock();
        writeOutput("Intelligence Staff " + std::to_string(staff->id) + " began reviewing logbook at time " + std::to_string(getTime()) + ". Operations completed = " + std::to_string(completedTasks));
        readerUnlock();
    }
    return NULL;
}

void *operativesWork(void *arg)
{
    Operative *operative = (Operative *)arg;

    std::string TS = "";
    std::string UNIT = "";
    std::string LEADER = "";
    if (EXTRA_LOGGING)
    {
        TS = "(TS" + to_string(operative->stationNum) + ") ";
        UNIT = " (Unit " + std::to_string(operative->unitNum) + ")";
        LEADER = (operative->isLeader) ? " (Leader)" : "";
    }

    usleep(getRandomNumber() * OPERATIVE_MULTIPLIER);

    writeOutput("Operative " + std::to_string(operative->identifier) + UNIT + LEADER + " has arrived at typewriting station " + TS + "at time " + std::to_string(getTime()));

    semWait(&stationSemaphores[operative->stationNum - 1]);
    usleep(x * 1000);
    writeOutput("Operative " + std::to_string(operative->identifier) + UNIT + LEADER + " has completed document recreation " + TS + "at time " + std::to_string(getTime()));
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
        writeOutput("Unit " + std::to_string(operative->unitNum) + " has completed document recreation phase at time " + std::to_string(getTime()));

        usleep(y * 1000); // y milliseconds
        completedTasks++;

        writeOutput("Unit " + std::to_string(operative->unitNum) + " has completed intelligence distribution at time " + std::to_string(getTime()));

        writerUnlock();
    }

    return NULL;
}

void cleanup()
{
    for (int i = 0; i < 4; i++)
    {
        semDestroy(&stationSemaphores[i]);
    }

    for (int i = 0; i < N / M; i++)
    {
        semDestroy(&groupSemaphores[i]);
    }

    mutexDestroy(&outputLock);
    mutexDestroy(&readCntLock);
    semDestroy(&writeSemaphore);
}

int main(int argc, char *argv[])
{
    if (argc != 3)
    {
        std::cerr << "Usage: ./a.out <input_file> <output_file>" << std::endl;
        return 0;
    }
    
    // check for intput file existence
    if(!std::ifstream(argv[1]))
    {
        std::cerr << "Error: Input file does not exist." << std::endl;
        return 1;
    }

    // File handling for input and output redirection
    std::ifstream inputFile(argv[1]);
    std::streambuf *cinBuffer = std::cin.rdbuf(); // Save original std::cin buffer
    std::cin.rdbuf(inputFile.rdbuf());            // Redirect std::cin to input file

    std::ofstream outputFile(argv[2]);
    std::streambuf *coutBuffer = std::cout.rdbuf(); // Save original cout buffer
    std::cout.rdbuf(outputFile.rdbuf());            // Redirect cout to output file

    std::cin >> N >> M;
    std::cin >> x >> y;

    if (N % M != 0)
    {
        std::cin.rdbuf(cinBuffer);
        std::cout.rdbuf(coutBuffer);
        std::cerr << "Error: N must be divisible by M." << std::endl;
        return 1;
    }

    // std::cout << "N: " << N << ", M: " << M << std::endl;
    // std::cout << "x: " << x << ", y: " << y << std::endl;

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

    // Restore std::cin and cout to their original states (console)
    std::cin.rdbuf(cinBuffer);
    std::cout.rdbuf(coutBuffer);

    return 0;
}