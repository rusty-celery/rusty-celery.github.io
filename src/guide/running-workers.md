# Running Workers

While the Python version of Celery provides a CLI that you can use to run a worker, in Rust you'll have to implement your own worker binary. However this is a lot easier than it sounds. At a minimum you just need to initialize your [`Celery`](https://docs.rs/celery/*/celery/struct.Celery.html) application, define and register your tasks, and run the [`Celery::consume`](https://docs.rs/celery/*/celery/struct.Celery.html#method.consume) method within an async executor.

Here is a complete example of a worker application:

```rust,no_run,noplaypen
#![allow(non_upper_case_globals)]

use celery::TaskResult;
use exitfailure::ExitFailure;

#[celery::task]
fn add(x: i32, y: i32) -> TaskResult<i32> {
    Ok(x + y)
}

#[tokio::main]
async fn main() -> Result<(), ExitFailure> {
    env_logger::init();

    let celery_app = celery::app!(
        broker = AMQP { std::env::var("AMQP_ADDR").unwrap() },
        tasks = [add],
        task_routes = [],
        prefetch_count = 2,
        acks_late = true,
        default_queue = "celery-rs",
    );

    celery_app.consume().await?;

    Ok(())
}
```

The `consume` method will listen for `SIGINT` and `SIGTERM` signals - just like a Python worker  - and will try to finish all pending tasks before shutting down unless it receives another signal.
