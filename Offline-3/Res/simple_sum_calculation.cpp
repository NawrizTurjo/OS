/*
  This program calculates the sum of all numbers from 1 to N using multiple
  threads. Each thread is responsible for summing a specific range of numbers,
  and the final sum is obtained by combining the partial sums from each thread.

  How it works:
    - N: The upper limit of the range (1 to N).
    - M: The number of threads to use for the calculation.
    - Each thread calculates the sum of a portion of the range, storing its
  result in a variable.
    - The main thread waits for all threads to finish, then combines their
  results to get the total sum.

  Compilation:
    g++ -pthread simple_sum_calculation.cpp -o a.out

  Usage:
    ./a.out

  Prepared by: Nafis Tahmid (1905002), Date: 10 November 2024
*/

#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#define RUNNING 1 // Define a constant for running state
#define FINISHED 0 // Define a constant for finished state

// Class to hold the data range and partial sum for each thread
class ThreadData {
public:
  long thread_num; // Thread number for identification
  long start;    // Start of the range for the thread
  long end;      // End of the range for the thread
  long long sum; // Sum computed by the thread in its range
  int status;
};

// Function that each thread runs to compute the sum in its range
void *computeSum(void *arg) {
  ThreadData *data = (ThreadData *)arg;
  data->sum = 0; // Initialize the thread's sum to zero
  for (int i = data->start; i <= data->end; i++) {
    data->sum += i; // Add each number in the range to the thread's sum
    // printf("Thread %ld: Current sum is %lld\n", data->thread_num, data->sum);
    // sleep(1);
  }
  data->status = FINISHED; // Set the status to finished after computation
  return NULL;
}

int main(void) {
  long N = 2441139;  // The upper limit for summing numbers :-)
  long M = 10;       // Number of threads
  long long sum = 0; // Variable to store the final sum

  // Array of threads
  pthread_t threads[M];
  // Array to store data (range and partial sum) for each thread
  ThreadData data[M];

  // Create M threads to compute parts of the sum
  for (int i = 0; i < M; i++) {
    // Define the range for each thread based on thread index
    data[i].start = i * N / M + 1;
    data[i].end = (i + 1) * N / M;
    data[i].thread_num = i + 1; // Assign thread number
    data[i].sum = 0; // Initialize the sum for this thread, maybe default ei 0 thake
    data[i].status = RUNNING; // Set the initial status to RUNNING
    // Create the thread, passing the thread's data as an argument
    pthread_create(&threads[i], NULL, computeSum, (void *)&data[i]);
  }
  sleep(0.2);

  // Join M threads to ensure main thread waits for all threads to finish
  // and accumulate the partial sums, otherwise the main thread may finish
  // before the threads and the sum will be incorrect
  for (int i = 0; i < M; i++) {
    // if the following line is commented, the program may output diffferent sum
    // in each run with same N
    // # Segmentation fault may occur if the threads are not joined
    // ? Because the main thread may finish before the threads complete
    // ? then the data[i] will be in the free region of memory
    // ? thus reclaiming this by other threads will cause a seg fault
    pthread_join(threads[i], NULL); // Wait for each thread to finish
    // if(data[i].status == FINISHED)
      sum += data[i].sum;             // Accumulate the sum from each thread
  }

  // Print the final computed sum
  printf("The sum of numbers between 1 to %ld is %lld\n", N, sum);

  return 0;
}

/*
  Prepared by: Nafis Tahmid (1905002), Date: 10 November 2024
*/
