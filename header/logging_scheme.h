#ifndef CLAUSE_LAB_LOGGING_SCHEME_H
#define CLAUSE_LAB_LOGGING_SCHEME_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define SAMPLING_RATIO 16

struct ClauseLogger {

  // A clause hash function receives an array of literals (a.k.a. pointer to first literal)
  //  and the clause size. It returns a hash.
  typedef size_t(*ClauseHashFunction)(int*, int);

  ClauseLogger(ClauseHashFunction hasher)  {
    m_hasher = hasher;
  }

  /**
   * Creates and opens a new file in:
   *     logging_dir "/produced_cls_" process_id "_" solver_id ".log"
   * @param logging_dir
   * @param process_id
   * @param solver_id
   */
  void open(const char *logging_dir, int process_id, int solver_id) {
    char *filename, *file;
    printf(filename, "/produced_cls_%d_%s.log", process_id, solver_id);
    file = concatenate(logging_dir, filename);
    m_fptr = fopen(file, "w");
    free(file);
    free(filename);
  }

  /**
   * Close the log file
   */
  void close() { fclose(m_fptr); }

  /**
   * Writes a report for a clause together with additional information.
   * @param clause
   * @param size
   * @param lbd
   * @param report_time
   */
  void log(int *clause, int size, int lbd, float report_time) {
    size_t hash = m_hasher(clause, size);
    if (hash % SAMPLING_RATIO == 0) {
      hash /= SAMPLING_RATIO;
      fprintf(m_fptr, "%f %llX %d %d", report_time, hash, size, lbd);
    }
  }

private:
  // pointer to file
  FILE *m_fptr;
  // clause hash function
  ClauseHashFunction m_hasher;

  /**************/
  /* Helpers    */
  /**************/
  char *int_to_str(int num) {
    int bufferSize = snprintf(NULL, 0, "%d", num) + 1;

    char *str = (char *)malloc(bufferSize);

    if (str == NULL) {
      fprintf(stderr, "Memory allocation failed\n");
      exit(1);
    }

    sprintf(str, "%d", num);

    return str;
  }

  char *concatenate(const char *str1, const char *str2) {
    size_t len1 = strlen(str1);
    size_t len2 = strlen(str2);

    char *result = (char *)malloc(len1 + len2 + 1);

    if (result == NULL) {
      fprintf(stderr, "Memory allocation failed\n");
      exit(1);
    }

    strcpy(result, str1);
    strcat(result, str2);

    return result;
  }
};

#endif // CLAUSE_LAB_LOGGING_SCHEME_H