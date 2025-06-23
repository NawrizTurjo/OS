#include <chrono>
#include <fstream>
#include <iostream>
#include <pthread.h>
#include <semaphore.h>
#include <random>
#include <unistd.h>
#include <vector>
using namespace std;

// Timing functions
auto start_time = std::chrono::high_resolution_clock::now();

/**
 * Get the elapsed time in milliseconds since the start of the simulation.
 * @return The elapsed time in milliseconds.
 */
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
    double lambda = 10000.234;
    std::poisson_distribution<int> poissonDist(lambda);
    return poissonDist(generator);
}

int N, M, x, y;

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

sem_t stationSemaphores[4]; // Semaphore for each station

void initStationSemaphores()
{
    for (int i = 0; i < 4; i++)
    {
        sem_init(&stationSemaphores[i], 0, 1);
    }
}

std::vector<sem_t> groupSemaphores;

void initGroupSemaphores()
{
    int groupCnt = N / M;
    for (int i = 0; i < N / M; i++)
    {
        sem_t sem;
        sem_init(&sem, 0, 0);
        groupSemaphores.push_back(sem);
    }
}

pthread_mutex_t output_lock; // Mutex lock for output synchronization

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
        operatives.emplace_back(Operative(i)); // Create and add Operative objects to the vector
    }

    initStationSemaphores(); // Initialize semaphores for each station
    initGroupSemaphores();   // Initialize semaphores for each group

    // Initialize mutex lock
    pthread_mutex_init(&output_lock, NULL);

    start_time = std::chrono::high_resolution_clock::now();
}

void *operativesWork(void *arg)
{
    Operative *operative = (Operative *)arg;

    usleep(get_random_number()); // Simulate some initial delay

    write_output("Operative " + std::to_string(operative->identifier) + " has arrived at typewriting station at time " + std::to_string(get_time()));

    sem_wait(&stationSemaphores[operative->stationNum - 1]); // Wait for the station semaphore
    usleep(x * 1000);
    write_output("Operative " + std::to_string(operative->identifier) + " has completed document recreation at time " + std::to_string(get_time()));
    sem_post(&stationSemaphores[operative->stationNum - 1]); // Release the station semaphore

    // # Leader part
    sem_post(&groupSemaphores[operative->unitNum - 1]); // Signal the group semaphore
    usleep(1000);

    if (operative->isLeader)
    {
        for (int i = 0; i < M; i++)
        {
            sem_wait(&groupSemaphores[operative->unitNum - 1]); // Wait for all operatives in the group
        }

        // ! ekhn shob operative e kaaj kore felse, so logbook e write kora jabe
        write_output("Unit " + std::to_string(operative->unitNum) + " has completed document recreation phase at time " + std::to_string(get_time()));

        usleep(y * 1000);

        write_output("Unit " + std::to_string(operative->unitNum) + " has completed intelligence distribution at time " + std::to_string(get_time()));
    }

    return NULL;
}

int main(int argc, char *argv[])
{
    if (argc != 3)
    {
        std::cout << "Usage: ./a.out <input_file> <output_file>" << std::endl;
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

    initialize(); // Initialize operatives and semaphores

    for (int i = 0; i < N; i++)
    {
        pthread_create(&operativesThreads[i], NULL, operativesWork, &operatives[i]);
    }

    for (int i = 0; i < N; i++)
    {
        pthread_join(operativesThreads[i], NULL);
    }

    // Restore std::cin and cout to their original states (console)
    std::cin.rdbuf(cinBuffer);
    std::cout.rdbuf(coutBuffer);

    return 0;
}