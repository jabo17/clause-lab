#ifndef CLAUSE_LAB_LOGGING_SCHEME_H
#define CLAUSE_LAB_LOGGING_SCHEME_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define SAMPLING_RATIO 16

struct ClauseOverlapLogger {

  // A clause hash function receives an array of literals (a.k.a. pointer to first literal)
  //  and the clause size. It returns a hash.
  typedef size_t(*ClauseHashFunction)(int*, int);

  ClauseOverlapLogger(ClauseHashFunction hasher)  {
    m_hasher = hasher;
  }

  /**
   * Creates and opens a new file in:
   *     <logging_dir>/<process_id>/produced_cls_<solver_id>.log
   * @param logging_dir directory for a single job (formula)
   * @param process_id
   * @param solver_id
   */
  void open(const char *logging_dir, size_t process_id, size_t solver_id) {
    int base_filename_size = 100;
    char *filename, *file;
    filename = (char*)(malloc(base_filename_size + 1));
    if (filename == NULL) {
      fprintf(stderr, "Memory allocation failed\n");
      exit(1);
    }
    while(true) {
      int n = snprintf(filename, base_filename_size, "/%s/produced_cls_%s.log", process_id, solver_id);
      if (n<0) {
        free(filename);
        base_filename_size *= 2;
        filename = (char*)malloc(base_filename_size+1);
        if (filename == NULL) {
          fprintf(stderr, "Memory allocation failed\n");
          exit(1);
        }
      }else{
        break;
      }
    }

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
      fprintf(m_fptr, "%f %lX %d %d", report_time, hash, size, lbd);
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
