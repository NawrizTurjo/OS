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

// Timing functions
auto start_time = std::chrono::high_resolution_clock::now();

long long get_time()
{
    auto end_time = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(
        end_time - start_time);
    long long elapsed_time_ms = duration.count();
    return elapsed_time_ms;
}

// Function to generate a Poisson-distributed random number
int get_random_number()
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
pthread_mutex_t readCntLock; // Mutex lock for read count
sem_t writeSemaphore;

std::vector<sem_t> stationSemaphores; // Semaphore for each station
std::vector<sem_t> groupSemaphores;
pthread_mutex_t output_lock;

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
std::vector<Operative> operatives; // Vector to store all operatives

// # Intelligent Staff class --- Task 2
class IntelligentStaff
{
public:
    int id;

    IntelligentStaff(int id) : id(id) {}
};
std::vector<IntelligentStaff> staffs; // Vector to store intelligent staff

void readerLock()
{
    pthread_mutex_lock(&readCntLock);

    readCnt++;
    if (readCnt == 1)
    {
        // This is the first reader, lock the writers
        sem_wait(&writeSemaphore);
    }

    pthread_mutex_unlock(&readCntLock);
}

void readerUnlock()
{
    pthread_mutex_lock(&readCntLock);

    readCnt--;
    if (readCnt == 0)
    {
        // This is the last reader, unlock the writers
        sem_post(&writeSemaphore);
    }

    pthread_mutex_unlock(&readCntLock);
}

void writerLock()
{
    // wait all other writers
    sem_wait(&writeSemaphore);
}

void writerUnlock()
{
    // signal as done
    sem_post(&writeSemaphore);
}

void initStationSemaphores()
{
    for (int i = 0; i < stationCnt; i++)
    {
        sem_t sem;
        sem_init(&sem, 0, 1);
        stationSemaphores.push_back(sem);
    }
}

void initGroupSemaphores()
{
    int groupCnt = N / M;
    for (int i = 0; i < groupCnt; i++)
    {
        sem_t sem;
        sem_init(&sem, 0, 0);
        groupSemaphores.push_back(sem);
    }
}

void initMutex()
{
    pthread_mutex_init(&output_lock, NULL);
    pthread_mutex_init(&readCntLock, NULL);
}

void initWriteSemaphore()
{
    sem_init(&writeSemaphore, 0, 1);
}

// uses mutex lock to write output to avoid interleaving
void write_output(std::string output)
{
    pthread_mutex_lock(&output_lock);
    std::cout << output << std::endl;
    // usleep(10000); // Sleep for 1 ms to simulate some delay in output
    pthread_mutex_unlock(&output_lock);
}

void initialize()
{
    for (int i = 1; i <= N; i++)
    {
        operatives.emplace_back(Operative(i));
    }

    for (int i = 0; i < numStaffs; i++)
    {
        staffs.emplace_back(IntelligentStaff(i + 1));
    }

    initStationSemaphores();
    initGroupSemaphores();
    initMutex();
    initWriteSemaphore();

    start_time = std::chrono::high_resolution_clock::now();
}

void *intelligentStaffsWork(void *arg)
{
    IntelligentStaff *staff = (IntelligentStaff *)arg;

    while (completedTasks < N / M)
    {
        usleep(1000);
        readerLock();
        write_output("Intelligence Staff " + std::to_string(staff->id) + " began reviewing logbook at time " + std::to_string(get_time()) + ". Operations completed = " + std::to_string(completedTasks));
        readerUnlock();
    }
    return NULL;
}

void *operativesWork(void *arg)
{
    Operative *operative = (Operative *)arg;

    std::string TS = "";
    if (EXTRA_LOGGING)
    {
        TS = "(TS" + to_string(operative->stationNum) + ") ";
    }

    usleep(get_random_number() * OPERATIVE_MULTIPLIER);

    write_output("Operative " + std::to_string(operative->identifier) + " has arrived at typewriting station " + TS + "at time " + std::to_string(get_time()));

    sem_wait(&stationSemaphores[operative->stationNum - 1]); // Wait for the station semaphore
    usleep(x * 1000);                                        // x milliseconds
    write_output("Operative " + std::to_string(operative->identifier) + " has completed document recreation " + TS + "at time " + std::to_string(get_time()));
    sem_post(&stationSemaphores[operative->stationNum - 1]); // Release the station semaphore

    // # Leader part
    sem_post(&groupSemaphores[operative->unitNum - 1]); // Signal the group semaphore
    // usleep(CIH_TIME);                                   // some delay to simulate the time to go to the TS to CIH

    // # This portion will be written into the logbook, so we need reader-writer locks
    if (operative->isLeader)
    {
        for (int i = 0; i < M; i++)
        {
            sem_wait(&groupSemaphores[operative->unitNum - 1]); // Wait for all operatives in the group
        }

        writerLock();

        // ! ekhn shob operative e kaaj kore felse, so logbook e write kora jabe
        write_output("Unit " + std::to_string(operative->unitNum) + " has completed document recreation phase at time " + std::to_string(get_time()));

        usleep(y * 1000); // y milliseconds
        completedTasks++;

        write_output("Unit " + std::to_string(operative->unitNum) + " has completed intelligence distribution at time " + std::to_string(get_time()));

        writerUnlock();
    }

    return NULL;
}

void cleanup()
{
    for (int i = 0; i < 4; i++)
    {
        sem_destroy(&stationSemaphores[i]); // Destroy each station semaphore
    }

    for (int i = 0; i < N / M; i++)
    {
        sem_destroy(&groupSemaphores[i]); // Destroy each group semaphore
    }

    pthread_mutex_destroy(&output_lock); // Destroy output mutex lock
    pthread_mutex_destroy(&readCntLock); // Destroy read count mutex lock
    sem_destroy(&writeSemaphore);        // Destroy write semaphore
}

int main(int argc, char *argv[])
{
    if (argc != 3)
    {
        std::cerr << "Usage: ./a.out <input_file> <output_file>" << std::endl;
        return 0;
    }

    // File handling for input and output redirection
    std::ifstream inputFile(argv[1]);
    std::streambuf *cinBuffer = std::cin.rdbuf(); // Save original std::cin buffer
    std::cin.rdbuf(inputFile.rdbuf());            // Redirect std::cin to input file

    std::ofstream outputFile(argv[2]);
    std::streambuf *coutBuffer = std::cout.rdbuf(); // Save original cout buffer
    std::cout.rdbuf(outputFile.rdbuf());            // Redirect cout to output file

    std::cin >> N >> M; // Read N and M from input file
    std::cin >> x >> y; // Read x and y from input file

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
        pthread_create(&operativesThreads[i], NULL, operativesWork, &operatives[i]);
    }
    pthread_t staffsThreads[numStaffs];

    for (int i = 0; i < numStaffs; i++)
    {
        pthread_create(&staffsThreads[i], NULL, intelligentStaffsWork, (void *)&staffs[i]);
    }

    for (int i = 0; i < N; i++)
    {
        pthread_join(operativesThreads[i], NULL);
    }

    for (int i = 0; i < numStaffs; i++)
    {
        pthread_join(staffsThreads[i], NULL);
    }

    cleanup();

    // Restore std::cin and cout to their original states (console)
    std::cin.rdbuf(cinBuffer);
    std::cout.rdbuf(coutBuffer);

    return 0;
}