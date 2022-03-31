# Coming from Python?

Though a lot of the Rusty Celery API is very similar to the Python equivalent - e.g. defining tasks by decorating functions - there are a few key differences listed here that have arisen because it was either not practical or just not possible to do it the same way as in Python.

In some cases this means the Rust equivalent is a little more verbose or takes a little more care on the user's end, but ultimately I think you'll find that the downsides of the Rust implementation are heavily outweighed by the benifits it brings: most notably speed, safety, and a much smaller memory footprint.

## Registering tasks

In Python you can register tasks by dynamically importing them at runtime through the [`imports`](https://docs.celeryq.dev/en/stable/userguide/configuration.html#imports) configuration field, but in Rust you need to manually register all tasks either as parameters to the [`app`](https://docs.rs/celery/*/celery/macro.app.html) macro or using the [`Celery::register_task`](https://docs.rs/celery/*/celery/struct.Celery.html#method.register_task) method:

```rust,no_run,noplaypen
# #![allow(non_upper_case_globals)]
# use exitfailure::ExitFailure;
# use celery::prelude::*;
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
