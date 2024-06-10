# ClauseLab

A tool for analysing clause overlaps in a distributed clause-sharing SAT solver.
It provides a C/C++ header to easily integrate a logging-scheme for learned clauses into a parallel or distributed
clause-sharing SAT solver.
After performing experiments, the reports can be extracted and evaluated with this tool.
The **Clause** **Lab**oratory provides an evaluation pipeline that allows to easily integrate further analyses.

---

## Usage

The following guide should help you to integrate the logging scheme and the evaluation pipeline into your clause-sharing solver.

### Logging Scheme

We provide a C/C++ Header to integrate our logging-scheme for learned clauses. The idea is to log a clause together with additional information
once it was learned, e.g. learned by some sequential SAT solver which want to export and share the clause with other solvers.
The logging scheme can be implemented using the following interface:
```c++
#define SAMPLING_RATIO 16

struct ClauseOverlapLogger {
  // A clause hash function receives an array of literals (a.k.a. pointer to first literal)
  //  and the clause size. It returns a hash.
  typedef size_t(*ClauseHashFunction)(int*, int);

  ClauseOverlapLogger(ClauseHashFunction hasher);

  /**
   * Creates and opens a new file in:
   *     <logging_dir>/<process_id>/produced_cls_<solver_id>.log
   * @param logging_dir directory for a single job (formula)
   * @param logging_dir
   * @param process_id
   * @param solver_id
   */
  void open(const char *logging_dir, size_t process_id, size_t solver_id);

  /**
   * Close the log file
   */
  void close();

  /**
   * Writes a report for a clause together with additional information.
   * @param clause
   * @param size
   * @param lbd
   * @param report_time
   */
  void log(int *clause, int size, int lbd, float report_time);
};
```

The class `ClauseLogger` is meant to be initialized once for every producing solver thread.
At construction, a clause hash function must be set by passing a function pointer of signature `(int* clause, int clause_size)` for hashing.
By calling `open(logging_dir, process_id, solver_id)`, it creates a new log file `logging_dir + "/produced_cls_" + proccess_id + "_" + solver_id ".log"` for this particular solver thread.
Once a formula was solved, it can be closed by calling `close`.

The `SAMPLING_RATIO` defines the fraction of sampled clauses, i.e. 1/`SAMPLING_RATIO`.

### Example Integration in [Mallob](https://github.com/domschrei/mallob)

The following shows an example integration with Mallob. It might help you to integrate clause logging and extraction in a similar way.

#### Logging Produced Clauses

Once a solver thread produced a clause, it calls a callback of the clause sharing manager that writes the clause after surviving clause filtering into an export buffer.
The following code snippets show the minor changes we have do make in the clause sharing manager in Mallob.

```c++
// sharing_manager.cpp from Mallob src/app/sat/sharing/sharing_manager.cpp

// create logs for a process and its solver threads
SharingManager::SharingManager(
		std::vector<std::shared_ptr<PortfolioSolverInterface>>& solvers, 
		const Parameters& params, const Logger& logger, size_t maxDeferredLitsPerSolver, int jobIndex, int formulaJobIndex)
	: _solvers(solvers), _params(params), _logger(logger), _job_index(jobIndex), _formula_job_index(formulaJobIndex)//, ...
{
    // ...

    for (size_t i = 0; i < _solvers.size(); i++) {
        // ...

        // log-file in logDir/appRank/localSolverID/ named produced_cls.{InternalJobID}.log
        // the member _clause_loggers is a std::vector<ClauseLogger>
        // Mallob::nonCommutativeHash is a non-commutative hash function for clauses defined in src/app/sat/data/clause.hpp 
        // note that a non-commutativ hash function is sufficient because the clause is sorted by literals before it is logged
        _clause_loggers.emplace_back({[](int* sortedClause, int clauseSize){return Mallob::nonCommutativeHash(sortedClause, clauseSize);}});
        _clause_loggers.back().open(_params.logDirectory.getValAsString().c_str(), _job_index, i);
    }

    // ...
}

// close the file streams
SharingManager::~SharingManager() {
    for (size_t i = 0; i < _solvers.size(); i++) {
        _clause_loggers[i].close();
    }
}

// callback called by solver threads
void SharingManager::onProduceClause(int solverId, int solverRevision, const Clause& clause, int condVarOrZero, bool recursiveCall) {

    // is clause of sufficiently small size and LDB ? Otherwise, return.
    // ...

    // Sort literals in clause 
    std::sort(clauseBegin+ClauseMetadata::numBytes(), clauseBegin+clauseSize);

    // the export buffer does clause filtering
    _export_buffer->produce(clauseBegin, clauseSize, clauseLbd, solverId, _internal_epoch);
    //log(V6_DEBGV, "%i : PRODUCED %s\n", solverId, tldClause.toStr().c_str());

    // log clause
    _clause_loggers[solverId].log(clause, clauseSize, clauseLbd, Timer::elapsedSeconds());
    
    if (tldClauseVec) delete tldClauseVec;
}
```

Now you can run Mallob on a benchmark and obtain the logs.
The easiest way is to call Mallob for each formula.
In this case, we configure Mallob to use as a logging dir `<logging_dir>/<formula_id>`.
In this directory, we create each processes `0` to `p-1` a directory.
Each process directory, will store the logs of its solver threads. 

#### Extracting Logs

The idea of extracting the logs is to obtain a single file for each formula with all logged clauses from all solver threads.
Our Mallob integration logs clauses as follows: `<logging_dir>/<formula_id>/<process_id>/produced_cls<solver_id>.log"`.
We provide a script supporting this file structure called "extract_cls_prod_logs.sh". It uses GNU parallel to process many 
formulas in parallel. The usage is as follows:
```bash
first_job_id=1 # smallest job id in $logging_dir of continuous job ids 
num_jobs=$(wc -l benchmark_file.txt |xargs)
logging_dir="main_logging_dir"
./extract_cls_prod_logs.sh --extract-all-parallel $first_job_id $num_jobs $logging_dir
# output: $logging_dir/jobs/<formula>/cls_produced_sorted.tar.gz"
# file format (whitespace separated): time, clause hash, clause size, clause lbd, process id, solver id
# the lines are sorted lexicographically by clause hash
```

#### Evaluation

Once the logs are extracted, we can evaluate the logged clauses. Therefore, we provide a range of analyses per default.
You can extend the evaluation pipeline with new analyses by writing plugins. See the section [plugins](#plugins) for more details.

The evaluation pipline first does formula specific evaluations and statistics and afterward does benchmark-wide statistics.
You can simply run it by calling the following:
```bash
logging_dir="main_logging_dir"
result_dir="some_result_dir"
rm -r $result_dir 2>/dev/null
mkdir $result_dir

instances=4 # number of formulas
num_par_jobs=4 # number of parallel jobs

# evaluate formulas (problem instances) 
./eval_cls_prod_logs.sh --eval-inst-all $logging_dir $result_dir $num_par_jobs #instances
# evaluate benchmark-wide
./eval_cls_prod_logs.sh  --eval-exp $logging_dir $result_dir
```

## Plugins

The evaluation pipeline supports multiple analyses producing different artefacts of statistics. 
The lists below shows the supported plugins. They need to be configured in `defs.sh`.

### List of Evaluation Plugins

#### Evaluating an Instance (Formula)
1. `dup_stat` counts the clause productions, unique clause hashes, duplicate clause productions, and duplicate clause hashes
   and writes them in this order into `$result_dir/<inst>/dup_stat.txt`.
2. `clause_size` outputs a file `$result_dir/<inst>/clause_size.txt` with a line for each clause size of the format
    `<clause_size> <reported clauses of this size> <duplicate reports of this size>`.
3. `clause_lbd` works similar to `clause_size`, but considers the LBD value.
4. `pairwise` determines the intersection and union of clause hashes produced by all solvers that were running on processes listed in `$PROCESSES_PAIRWISE`.
   A line in the output file `$result_dir/<inst>/pw_dup_stat.txt` contain for each pair of solvers $((p_1, s_1), (p_2, s_2))$ a line
    ``<s_1> <p_1> <s_2> <p_2> <intersection> <union>``. 
   The pairwise analysis fails to prevent noise if not all solvers from the process reported clauses, because it can indicate that a deviant number of solvers was running.
5. `time_dup_rel` outputs all relative timestamps of duplicate reports with respect to their first appearance/found. 
   It allows one to analysis how long it typically takes until a clause is reproduced. The file is located in `$result_dir/<inst>/time_dup_rel.txt`.
   
#### Evaluating over an Experiment (All Formulas)
The following plugins evaluate statistics over all artefacts generated by the instance-specific plugins.
They print statistics such as geometric means, quartiles, min, max, arithmetic mean to standard output for various metrics.
Moreover, they create plots with `matplotlib` and `python3`.
1. `dup_stat` aggregates the duplicate statistic for each formula and outputs a file `$result_dir/dup_stat.txt` where lines are of the format:
   `<inst> <clause productions> <unique hashes> <duplicate clause productions> <duplicate hashes>`.
    Moreover, it creates a boxplot `$result_dir/boxplot_dcpr.pdf` that plots the distribution of the Duplicate Production Clause Ratio (DCPR)
    over all (1) instances, (2) satisfiable, and (3) unsatisfiable formulas by using the `$QUALIFIED_SOLUTION_STATUS` defined in `defs.sh`.
2. `clause_size` computes for each clause size the geometric mean over the instances' fraction of reports and fraction of duplicate reports.
    They are written to `$result_dir/cls_clause_size_stat_gmean.txt` and plotted in a barplot `$result_dir/barplot_clause_size.pdf`.
3. `clause_lbd` works similar to `clause_size`.
4. `pairwise` generates a heatmap showing for each pair of solvers the geometric mean and maximum PPCO over all instances.
    Note that the title in the plot shows in brackets the number of involved formulas. The set of instances for each pair of solvers for the geometric mean can slightly vary
    due to null-valued PPCOs.
5. `time_dup_rel` generates a CDF plot to analysis the typical relative timestamps among the total set of duplicate reports from the experiment.
    It generates CDFs for different sets of instances by requiring different minimum running times specified in `$exp_dir/$QUALIFIED_RUNTIMES` (see `defs.sh`).

### Adding Evaluation Plugins

It is possible that you need extra plugins to analysis the logged clauses. 
1. Add your plugins by creating a shell script in `plugins/exp` and `plugins/inst` to analysis your whole experiment and solved formulas, respectively.
2. Register your plugins in `register_plugin.sh`. 

# License

If you use "ClauseLab" for a publication, please acknowledge our work by citing the following paper.

```text
bibtex entry
```


