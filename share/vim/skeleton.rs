/*
my_name < email@example.com >

DESCRIPTION:
  Demo skeleton showing scoped-thread cleanup: submit N items, always wait for
  completion, collect results & errors. Standard library only, so it builds with
  a bare `rustc` -- no Cargo project or external crates required.

USAGE:
  rustc skeleton.rs -o skeleton \
    && ./skeleton 1 2 --required foo --sum --move paper --workers 8 --fail-prob 0.3

LICENSE: ____
*/

use std::collections::VecDeque;
use std::env;
use std::process::ExitCode;
use std::sync::{Arc, Mutex};
use std::thread;
use std::time::Duration;

const VERSION: &str = "0.0.1";

// --- CLI parsing ------------------------------------------------------------

#[derive(Clone, Copy, Debug)]
enum Accumulate {
    Sum,
    Max,
}

#[derive(Debug)]
struct Options {
    integers: Vec<i64>,
    accumulate: Accumulate,
    chosen_move: Option<String>,
    required: Option<String>,
    workers: Option<usize>,
    fail_prob: f64,
    seed: Option<u64>,
    verbose: u8,
    debug: bool,
}

fn usage(prog: &str) -> String {
    format!(
        "Usage: {prog} N [N ...] --required VAL [options]\n\
         \n\
         Options:\n  \
         --sum              Sum the integers (default: find the max)\n  \
         --move MOVE        Choose: rock | paper | scissors\n  \
         --required VAL     A required option\n  \
         --workers N        Max worker threads (default: auto)\n  \
         --fail-prob P      Probability a task fails (0.0-1.0, default 0.30)\n  \
         --seed SEED        Random seed for reproducibility\n  \
         -v, --verbose      Increase verbosity (repeat for more)\n  \
         -D, --debug        Show debug messages\n  \
         -h, --help         Show this help and exit\n      \
         --version      Show version and exit"
    )
}

// Parse argv into Options. Returns Err(exit_code) after printing a message when
// the arguments are invalid or a terminating flag (--help/--version) was seen.
fn parse_args(argv: &[String]) -> Result<Options, u8> {
    let prog = argv
        .first()
        .map(|p| p.rsplit('/').next().unwrap_or(p).to_string())
        .unwrap_or_else(|| "skeleton".to_string());

    let mut opts = Options {
        integers: Vec::new(),
        accumulate: Accumulate::Max,
        chosen_move: None,
        required: None,
        workers: None,
        fail_prob: 0.30,
        seed: None,
        verbose: 0,
        debug: env::var_os("DEBUG").is_some(),
    };

    // Consume flags and positionals. `iter` lets us pull the value of options
    // that take an argument (e.g. `--required foo`).
    let mut iter = argv.iter().skip(1);
    while let Some(arg) = iter.next() {
        let mut next_value = |flag: &str| -> Result<String, u8> {
            iter.next().cloned().ok_or_else(|| {
                eprintln!("ERROR: missing argument for {flag}");
                2
            })
        };

        match arg.as_str() {
            "--sum" => opts.accumulate = Accumulate::Sum,
            "--move" => opts.chosen_move = Some(next_value("--move")?),
            "--required" => opts.required = Some(next_value("--required")?),
            "--workers" => {
                let raw = next_value("--workers")?;
                opts.workers = Some(raw.parse().map_err(|_| {
                    eprintln!("ERROR: --workers expects an integer (got {raw:?})");
                    2
                })?);
            }
            "--fail-prob" => {
                let raw = next_value("--fail-prob")?;
                opts.fail_prob = raw.parse().map_err(|_| {
                    eprintln!("ERROR: --fail-prob expects a float (got {raw:?})");
                    2
                })?;
            }
            "--seed" => {
                let raw = next_value("--seed")?;
                opts.seed = Some(raw.parse().map_err(|_| {
                    eprintln!("ERROR: --seed expects an integer (got {raw:?})");
                    2
                })?);
            }
            "-v" | "--verbose" => opts.verbose = opts.verbose.saturating_add(1),
            "-D" | "--debug" => {
                opts.debug = true;
                opts.verbose = 10;
            }
            "-h" | "--help" => {
                println!("{}", usage(&prog));
                return Err(0);
            }
            "--version" => {
                println!("{VERSION}");
                return Err(0);
            }
            other if other.starts_with('-') && other != "-" => {
                eprintln!("ERROR: unknown option {other:?}\n\n{}", usage(&prog));
                return Err(2);
            }
            other => match other.parse::<i64>() {
                Ok(n) => opts.integers.push(n),
                Err(_) => {
                    eprintln!("Non-integer positional argument: {other:?}");
                    return Err(2);
                }
            },
        }
    }

    if opts
        .chosen_move
        .as_deref()
        .is_some_and(|m| !matches!(m, "rock" | "paper" | "scissors"))
    {
        eprintln!("--move must be one of: rock | paper | scissors");
        return Err(2);
    }

    if opts.integers.is_empty() {
        eprintln!(
            "At least one positional integer N is required.\n\n{}",
            usage(&prog)
        );
        return Err(2);
    }

    if opts.required.is_none() {
        eprintln!("--required is mandatory.\n\n{}", usage(&prog));
        return Err(2);
    }

    if !(0.0..=1.0).contains(&opts.fail_prob) {
        eprintln!(
            "--fail-prob must be between 0.0 and 1.0 (got {})",
            opts.fail_prob
        );
        return Err(2);
    }

    Ok(opts)
}

// --- tiny std-only RNG ------------------------------------------------------

// xorshift64: good enough to demo reproducible `--seed` without pulling in the
// `rand` crate, which would force a Cargo project.
struct Rng {
    state: u64,
}

impl Rng {
    fn new(seed: u64) -> Self {
        // Avoid the all-zero state, which xorshift cannot escape.
        Rng {
            state: if seed == 0 {
                0x9E37_79B9_7F4A_7C15
            } else {
                seed
            },
        }
    }

    fn next_u64(&mut self) -> u64 {
        let mut x = self.state;
        x ^= x << 13;
        x ^= x >> 7;
        x ^= x << 17;
        self.state = x;
        x
    }

    // Uniform float in [0.0, 1.0) using the top 53 bits.
    fn next_f64(&mut self) -> f64 {
        (self.next_u64() >> 11) as f64 / (1u64 << 53) as f64
    }
}

// --- workload ---------------------------------------------------------------

fn handle(item: i64, fail_prob: f64, rng: &Arc<Mutex<Rng>>) -> Result<String, String> {
    // Draw once under the lock, then release it before sleeping so workers do
    // not serialize on the RNG.
    let roll = {
        let mut guard = rng.lock().expect("rng poisoned");
        thread::sleep(Duration::from_millis(50 + (guard.next_u64() % 200)));
        guard.next_f64()
    };
    if roll < fail_prob {
        Err(format!("boom on {item}"))
    } else {
        Ok(format!("processed {item}"))
    }
}

// --- orchestration with scoped-thread cleanup -------------------------------

// `thread::scope` is Rust's ensure-style cleanup: every worker is guaranteed to
// be joined before the function returns, even on early exit or panic unwind.
fn process_all(
    items: Vec<i64>,
    max_workers: Option<usize>,
    fail_prob: f64,
    seed: Option<u64>,
    verbose: bool,
) -> (Vec<String>, Vec<(i64, String)>) {
    let worker_count = max_workers
        .filter(|&n| n > 0)
        .or_else(|| thread::available_parallelism().ok().map(|n| n.get()))
        .unwrap_or(4)
        .max(1);

    let queue = Arc::new(Mutex::new(VecDeque::from(items)));
    let results = Arc::new(Mutex::new(Vec::new()));
    let errors = Arc::new(Mutex::new(Vec::new()));
    let rng = Arc::new(Mutex::new(Rng::new(seed.unwrap_or(0))));

    thread::scope(|scope| {
        for _ in 0..worker_count {
            let queue = Arc::clone(&queue);
            let results = Arc::clone(&results);
            let errors = Arc::clone(&errors);
            let rng = Arc::clone(&rng);
            scope.spawn(move || loop {
                let item = match queue.lock().expect("queue poisoned").pop_front() {
                    Some(item) => item,
                    None => break,
                };
                match handle(item, fail_prob, &rng) {
                    Ok(out) => {
                        if verbose {
                            println!("[ok] {out}");
                        }
                        results.lock().expect("results poisoned").push(out);
                    }
                    Err(err) => {
                        if verbose {
                            eprintln!("[err] item={item} err={err}");
                        }
                        errors.lock().expect("errors poisoned").push((item, err));
                    }
                }
            });
        }
    });

    // Reclaim the collected data now that every worker has been joined.
    let results = Arc::try_unwrap(results)
        .expect("workers joined")
        .into_inner()
        .expect("results poisoned");
    let errors = Arc::try_unwrap(errors)
        .expect("workers joined")
        .into_inner()
        .expect("errors poisoned");
    (results, errors)
}

// --- main -------------------------------------------------------------------

fn run(argv: &[String]) -> ExitCode {
    let args = match parse_args(argv) {
        Ok(args) => args,
        Err(code) => return ExitCode::from(code),
    };

    if args.debug {
        eprintln!("DEBUG: parsed args = {args:?}");
    }

    let accumulated = match args.accumulate {
        Accumulate::Sum => args.integers.iter().sum(),
        Accumulate::Max => *args.integers.iter().max().expect("non-empty by parse_args"),
    };
    let items: Vec<i64> = (0..accumulated).collect();

    let (results, errors) = process_all(
        items,
        args.workers,
        args.fail_prob,
        args.seed,
        args.verbose > 0,
    );

    println!("Results:");
    for r in &results {
        println!("  {r}");
    }

    println!("\nErrors:");
    for (item, err) in &errors {
        println!("  item={item} err={err}");
    }

    if let Some(chosen) = &args.chosen_move {
        println!("\nYou played: {chosen}");
    }

    if errors.is_empty() {
        ExitCode::SUCCESS
    } else {
        ExitCode::FAILURE
    }
}

fn main() -> ExitCode {
    let argv: Vec<String> = env::args().collect();
    run(&argv)
}
