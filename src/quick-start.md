# Quick Start

Rusty Celery is provided as the [`celery`](https://crates.io/crates/celery) library on crates.io. To get started, add `celery` as a dependency to your project. Then you can define tasks by decorating functions with the [`task`](https://docs.rs/celery/*/celery/attr.task.html) attribute:

```rust,noplaypen
# use celery::task;
#[task]
fn add(x: i32, y: i32) -> i32 {
    x + y
}
```

And create a [`Celery`](https://docs.rs/celery/*/celery/struct.Celery.html) app with the [`celery_app`](https://docs.rs/celery/*/celery/macro.celery_app.html) macro:

```rust,no_run,noplaypen
# use celery::{celery_app, task, AMQPBroker};
# #[task]
# fn add(x: i32, y: i32) -> i32 {
#     x + y
# }
let my_app = celery_app!(
    broker = AMQPBroker { std::env::var("AMQP_ADDR").unwrap() },
    tasks = [add],
    task_routes = [],
);
```

The Celery app can be used as either a producer or consumer (worker). To send tasks to a
queue for a worker to consume, use the [`Celery::send_task`](https://docs.rs/celery/*/celery/struct.Celery.html#method.send_task) method:

```rust,no_run,noplaypen
# use celery::{celery_app, task, AMQPBroker};
# #[task]
# fn add(x: i32, y: i32) -> i32 {
#     x + y
# }
# #[tokio::main]
# async fn main() -> Result<(), exitfailure::ExitFailure> {
# let my_app = celery_app!(
#     broker = AMQPBroker { std::env::var("AMQP_ADDR").unwrap() },
#     tasks = [add],
#     task_routes = [],
# );
my_app.send_task(add::new(1, 2)).await?;
#   Ok(())
# }
```

And to act as worker and consume tasks sent to a queue by a producer, use the
[`Celery::consume`](https://docs.rs/celery/*/celery/struct.Celery.html#method.consume) method:

```rust,no_run,noplaypen
# use celery::{celery_app, task, AMQPBroker};
# #[task]
# fn add(x: i32, y: i32) -> i32 {
#     x + y
# }
# #[tokio::main]
# async fn main() -> Result<(), exitfailure::ExitFailure> {
# let my_app = celery_app!(
#     broker = AMQPBroker { std::env::var("AMQP_ADDR").unwrap() },
#     tasks = [add],
#     task_routes = [],
# );
my_app.consume().await?;
# Ok(())
# }
```
