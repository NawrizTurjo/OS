/**
 * @file semaphore.c
 * @brief Demonstration of thread synchronization using semaphores in C
 *
 * This program creates two threads (main thread and a worker thread) that 
 * synchronize access to a critical section using a binary semaphore.
 * Both threads enter an infinite loop where they wait for semaphore access,
 * prompt for user input, display the input, and release the semaphore.
 * 
 * The code also includes commented-out mutex synchronization as an alternative approach.
 *
 * @note This program runs indefinitely and must be terminated manually (Ctrl+C)
 */

/**
 * @var bin_sem
 * @brief Binary semaphore used for thread synchronization
 */

/**
 * @var mtx
 * @brief Mutex for thread synchronization (currently unused/commented out)
 */

/**
 * @var message
 * @brief Global buffer to store user input
 */

/**
 * @function thread_function
 * @brief Worker thread function that demonstrates semaphore usage
 * 
 * This function runs in an infinite loop that:
 * 1. Waits to acquire the binary semaphore
 * 2. Prints a message when it enters the critical section
 * 3. Accepts user input
 * 4. Displays the input
 * 5. Releases the semaphore
 *
 * @param arg Pointer to function arguments (unused)
 * @return NULL (never returns due to infinite loop)
 */

/**
 * @function main
 * @brief Main entry point that creates a worker thread and demonstrates semaphore usage
 * 
 * This function:
 * 1. Initializes the semaphore and mutex
 * 2. Sets up thread attributes for round-robin scheduling
 * 3. Creates a worker thread running thread_function
 * 4. Enters an infinite loop similar to thread_function
 * 5. Uses semaphore to synchronize with the worker thread
 *
 * @return 0 (never returns due to infinite loop)
 */
#include<stdio.h>
#include<pthread.h>
#include<semaphore.h>
#include<unistd.h>

sem_t bin_sem;
pthread_mutex_t mtx;
char message[100];



void * thread_function(void * arg)
{	
	int x;
	char message2[10];
	while(1)
	{	
		printf("thread2:waiting..\n");
		//pthread_mutex_lock(&mtx);
		sem_wait(&bin_sem);		
		printf("hi i am the new thread waiting inside critical..\n");
		scanf("%s",message);
		printf("You entered:%s\n",message);
		sem_post(&bin_sem);
		//pthread_mutex_unlock(&mtx);
	
	}
	
}

int main(void)
{
	pthread_t athread;
	pthread_attr_t ta;
	char message2[10];
	int x;
	sem_init(&bin_sem,0,1);
	pthread_mutex_init(&mtx,NULL);
	
	pthread_attr_init(&ta);
	pthread_attr_setschedpolicy(&ta,SCHED_RR);	                                                                                                                                                                                                     

	pthread_create(&athread,&ta,thread_function,NULL);
	while(1)
	{	
		//pthread_mutex_lock(&mtx);
		printf("main waiting..\n");
		sem_wait(&bin_sem);	
		printf("hi i am the main thread waiting inside critical..\n");
		scanf("%s",message);
		printf("You entered:%s\n",message);
		sem_post(&bin_sem);
		//pthread_mutex_unlock(&mtx);
	}
	sleep(5);		
}
