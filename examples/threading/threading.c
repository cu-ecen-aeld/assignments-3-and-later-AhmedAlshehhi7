#include "threading.h"
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>

// Optional: use these functions to add debug or error prints to your application
#define DEBUG_LOG(msg,...)
//#define DEBUG_LOG(msg,...) printf("threading: " msg "\n", ##__VA_ARGS__)
#define ERROR_LOG(msg,...) printf("threading ERROR: " msg "\n", ##__VA_ARGS__)

void* threadfunc(void* thread_param)
{
    // Cast the parameter to our thread_data structure
    struct thread_data* thread_args = (struct thread_data*) thread_param;

    // Wait for the specified time before attempting to lock the mutex
    usleep(thread_args->wait_to_obtain_ms * 1000);  // convert milliseconds to microseconds

    // Attempt to lock the mutex
    if (pthread_mutex_lock(thread_args->mutex) != 0) {
        ERROR_LOG("Failed to lock mutex");
        thread_args->thread_complete_success = false;
        return thread_param;
    }

    // Once the mutex is locked, wait for the specified time
    usleep(thread_args->wait_to_release_ms * 1000);  // convert milliseconds to microseconds

    // Release the mutex
    if (pthread_mutex_unlock(thread_args->mutex) != 0) {
        ERROR_LOG("Failed to unlock mutex");
        thread_args->thread_complete_success = false;
        return thread_param;
    }

    // Indicate that the thread executed successfully
    thread_args->thread_complete_success = true;

    // Return the pointer to the thread data so the joiner can free it and check the status
    return thread_param;
}

bool start_thread_obtaining_mutex(pthread_t *thread, pthread_mutex_t *mutex,
                                  int wait_to_obtain_ms, int wait_to_release_ms)
{
    // Dynamically allocate memory for the thread_data structure
    struct thread_data *data = malloc(sizeof(struct thread_data));
    if (data == NULL) {
        ERROR_LOG("Failed to allocate memory for thread_data");
        return false;
    }

    // Initialize the thread_data members with the provided parameters
    data->mutex = mutex;
    data->wait_to_obtain_ms = wait_to_obtain_ms;
    data->wait_to_release_ms = wait_to_release_ms;
    data->thread_complete_success = false;  // Default to false until the thread completes

    // Create the thread; the new thread will start in threadfunc() and receive 'data' as its argument
    int rc = pthread_create(thread, NULL, threadfunc, data);
    if (rc != 0) {
        ERROR_LOG("pthread_create failed");
        free(data);
        return false;
    }

    return true;
}

