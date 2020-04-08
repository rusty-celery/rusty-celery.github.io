# Coming from Python?

Though a lot of the Rusty Celery API is very similar to the Python equivalent - e.g. defining tasks by decorating functions - there are a few key differences listed here that have arisen because it was either not practical or just not possible to do it the same way as in Python.

In some cases this means the Rust equivalent is a little more verbose or takes a little more care on the user's end, but ultimately I think you'll find that the downsides of the Rust implementation are heavily outweighed by the benifits it brings: most notably speed, safety, and a much smaller memory footprint.

## Registering tasks

In Python you can register tasks by dynamically importing them at runtime through the [`imports`](https://docs.celeryproject.org/en/stable/userguide/configuration.html#imports) configuration field, but in Rust you need to manually register all tasks either as parameters to the [`app`](https://docs.rs/celery/*/celery/macro.app.html) macro or using the [`Celery::register_task`](https://docs.rs/celery/*/celery/struct.Celery.html#method.register_task) method:

```rust,no_run,noplaypen
# #![allow(non_upper_case_globals)]
# use exitfailure::ExitFailure;
# use celery::TaskResult;
# #[tokio::main]
# async fn main() -> Result<(), ExitFailure> {
# let my_app = celery::app!(
#     broker = AMQP { std::env::var("AMQP_ADDR").unwrap() },
#     tasks = [],
#     task_routes = [],
# );
#[celery::task]
fn add(x: i32, y: i32) -> TaskResult<i32> {
    Ok(x + y)
}

my_app.register_task::<add>().await.unwrap();
# Ok(())
# }
```

## Time limits vs timeout

In Python you configure tasks to have a [soft or hard time limit](https://docs.celeryproject.org/en/latest/userguide/workers.html#time-limits). A soft time limit allows a task to clean up after itself if it runs over the limit, while a hard limit will force terminate the task.

In Rust we've replaced these with a single configuration option: [`timeout`](https://docs.rs/celery/*/celery/task/struct.TaskOptions.html#structfield.timeout). A worker will wait `timeout` seconds for a task to finish and then will interrupt it if it hasn't completed in time. After a task is interrupted, its [`on_failure`](https://docs.rs/celery/*/celery/task/trait.Task.html#method.on_failure) callback will be called with the [`TimeoutError`](https://docs.rs/celery/*/celery/error/enum.TaskError.html#variant.TimeoutError) variant.

> NOTE: It's only possible to interrupt non-blocking operations since tasks don't run in their own dedicated threads. This means that while a running task is blocking it will not respect its `timeout` until it unblocks. Therefore you should be careful to only use non-blocking IO functions.
