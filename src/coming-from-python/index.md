# Coming from Python?

Though a lot of the Rusty Celery API is very similar to the Python equivalent - e.g. defining tasks by decorating functions - there are a few key differences listed here that have arisen because it was either not practical or just not possible to do it the same way as in Python.

In some cases this means the Rust equivalent is a little more verbose or takes a little more care on the user's end, but ultimately I think you'll find that the downsides of the Rust implementation are heavily outweighed by the benifits it brings: most notably speed, safety, and a much smaller memory footprint.

### Registering tasks

In Python you can register tasks by dynamically importing them at runtime through the [`imports`](https://docs.celeryproject.org/en/stable/userguide/configuration.html#imports) configuration field, but in Rust you need to manually register all tasks using the [`Celery::register_task`](https://docs.rs/celery/*/celery/struct.Celery.html#method.register_task) method:

```rust,no_run
# #![allow(non_upper_case_globals)]
# use celery::{self, task, AMQPBroker};
# use exitfailure::ExitFailure;
# celery::celery_app!(
#     my_app,
#     AMQPBroker { std::env::var("AMQP_ADDR").unwrap() },
# );
#[task]
fn add(x: i32, y: i32) -> i32 {
    x + y
}

my_app.register_task::<add>().unwrap();
```

### Running a worker

While Python Celery provides a CLI that you can use to run a worker, in Rust you'll have to implement your own worker binary. However this is a lot easier than it sounds. At a minimum you just need to initialize your [`Celery`](https://docs.rs/celery/*/celery/struct.Celery.html) application, define and register your tasks, and run the [`Celery::consume`](https://docs.rs/celery/*/celery/struct.Celery.html#method.consume) method within your `main` function.

Note that `Celery::consume` is an `async` method though, which means you need an async runtime to execute it. Luckily this is provided by [`tokio`](https://docs.rs/tokio/*/tokio/) and is as simple as declaring your `main` function `async` and decorating it with the `tokio::main` macro.

Here is a complete example of a worker application:

```rust,no_run
#![allow(non_upper_case_globals)]

use celery::{self, task, AMQPBroker};
use exitfailure::ExitFailure;

#[task]
fn add(x: i32, y: i32) -> i32 {
    x + y
}

celery::celery_app!(
    celery_app,
    AMQPBroker { std::env::var("AMQP_ADDR").unwrap() },
    tasks = [add],
    prefetch_count = 2,
    default_queue_name = "celery-rs",
);

#[tokio::main]
async fn main() -> Result<(), ExitFailure> {
    env_logger::init();
    celery_app.consume("celery-rs").await?;
    Ok(())
}
```
