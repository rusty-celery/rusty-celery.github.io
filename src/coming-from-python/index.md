# Coming from Python?

Though a lot of the Rusty Celery API is very similar to the Python equivalent - e.g. defining tasks by decorating functions - there are a few key differences listed here that have arisen because it was either not practical or just not possible to do it the same way as in Python.

In some cases this means the Rust equivalent is a little more verbose or takes a little more care on the user's end, but ultimately I think you'll find that the downsides of the Rust implementation are heavily outweighed by the benifits it brings: most notably speed, safety, and a much smaller memory footprint.

## Registering tasks

In Python you can register tasks by dynamically importing them at runtime through the [`imports`](https://docs.celeryproject.org/en/stable/userguide/configuration.html#imports) configuration field, but in Rust you need to manually register all tasks either as parameters to the [`app`](https://docs.rs/celery/*/celery/macro.app.html) macro or using the [`Celery::register_task`](https://docs.rs/celery/*/celery/struct.Celery.html#method.register_task) method:

```rust,no_run,noplaypen
# #![allow(non_upper_case_globals)]
# use exitfailure::ExitFailure;
# let my_app = celery::app!(
#     broker = AMQP { std::env::var("AMQP_ADDR").unwrap() },
#     tasks = [],
#     task_routes = [],
# );
#[celery::task]
fn add(x: i32, y: i32) -> i32 {
    x + y
}

my_app.register_task::<add>().unwrap();
```

## Running a worker

While Python Celery provides a CLI that you can use to run a worker, in Rust you'll have to implement your own worker binary. However this is a lot easier than it sounds. At a minimum you just need to initialize your [`Celery`](https://docs.rs/celery/*/celery/struct.Celery.html) application, define and register your tasks, and run the [`Celery::consume`](https://docs.rs/celery/*/celery/struct.Celery.html#method.consume) method within your `main` function.

Note that `Celery::consume` is an `async` method though, which means you need an async runtime to execute it. Luckily this is provided by [`tokio`](https://docs.rs/tokio/*/tokio/) and is as simple as declaring your `main` function `async` and decorating it with the `tokio::main` macro.

Here is a complete example of a worker application:

```rust,no_run,noplaypen
#![allow(non_upper_case_globals)]

use exitfailure::ExitFailure;

#[celery::task]
fn add(x: i32, y: i32) -> i32 {
    x + y
}

#[tokio::main]
async fn main() -> Result<(), ExitFailure> {
    env_logger::init();

    let celery_app = celery::app!(
        broker = AMQP { std::env::var("AMQP_ADDR").unwrap() },
        tasks = [add],
        task_routes = [],
        prefetch_count = 2,
        default_queue = "celery-rs",
    );

    celery_app.consume().await?;

    Ok(())
}
```

The `consume` method will listen for `SIGINT` and `SIGTERM` signals - just like a Python worker  - and will try to finish all pending tasks before shutting down unless it receives another signal.

## Time limits vs timeout

In Python you configure tasks to have a [soft or hard time limit](https://docs.celeryproject.org/en/latest/userguide/workers.html#time-limits). A soft time limit allows a task to clean up after itself if it runs over the limit, while a hard limit will force terminate the task.

In Rust we've replaced these with a single configuration option: [`timeout`](https://docs.rs/celery/*/celery/task/struct.TaskOptions.html#structfield.timeout). A worker will wait `timeout` seconds for a task to finish and then will interrupt it if it hasn't completed in time. After a task is interrupted, its [`on_failure`](https://docs.rs/celery/*/celery/task/trait.Task.html#method.on_failure) callback will be called with the [`TimeoutError`](https://docs.rs/celery/*/celery/error/enum.TaskError.html#variant.TimeoutError) variant.

> NOTE: It's only possible to interrupt non-blocking operations since tasks don't run in their own dedicated threads. This means that while a running task is blocking it will not respect its `timeout` until it unblocks. Therefore you should be careful to only use non-blocking IO functions.
