#include<stdio.h>
#include<pthread.h>
#include<stdlib.h>
#include<unistd.h>

/*
	These are not synchronized threads, they share a common variable 'n'.
	Both threads increment the value of 'n' concurrently
	and print it. The output may vary in each run due to the
	synchronization issues.
*/

// # That's why we use mutex or semaphore to synchronize threads

void * threadFunc1(void * arg)
{
	int i;
	int * a = (int *)arg;
	for(i=1;i<=5;i++)
	{
		// printf("%s\n",(char*)arg);
		printf("thread1: %d\n",*a);
		*a = *a + 1; // increment the value pointed by a
		sleep(1);
	}
}

void * threadFunc2(void * arg)
{
	int i;
	int * a = (int *)arg;
	for(i=1;i<=5;i++)
	{
		// printf("%s\n",(char*)arg);
		printf("thread2: %d\n",*a);
		*a = *a + 1; // increment the value pointed by a
		sleep(1);
	}
}





int main(void)
{	
	pthread_t thread1;
	pthread_t thread2;
	
	char * message1 = "i am thread 1";
	char * message2 = "i am thread 2";	

	int n = 1;
	
	pthread_create(&thread1,NULL,threadFunc1,(void*)&n );
	pthread_create(&thread2,NULL,threadFunc2,(void*)&n );

	while(1);
	return 0;
}

/*
Log outputs:
1.
	thread1: 1
	thread1: 2
	thread1: 3
	thread1: 4
	thread1: 5
	thread2: 6
	thread2: 7
	thread2: 8
	thread2: 9
	thread2: 10
2.
	thread1: 1
	thread2: 1
	thread1: 3
	thread2: 3
	thread1: 5
	thread2: 5
	thread1: 7
	thread2: 7
	thread1: 9
	thread2: 9
3.
	thread1: 1
	thread2: 1
	thread1: 3
	thread2: 4
	thread1: 5
	thread2: 6
	thread1: 7
	thread2: 8
	thread1: 9
	thread2: 10
*/