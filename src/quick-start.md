# Quick Start

Rusty Celery is provided as the [`celery`](https://crates.io/crates/celery) library on crates.io. To get started, add `celery` as a dependency to your project. Then you can define tasks by decorating functions with the [`task`](https://docs.rs/celery/*/celery/attr.task.html) attribute:

```rust,noplaypen
use celery::TaskResult;

#[celery::task]
fn add(x: i32, y: i32) -> TaskResult<i32> {
    Ok(x + y)
}
```

And create a [`Celery`](https://docs.rs/celery/*/celery/struct.Celery.html) app with the [`app`](https://docs.rs/celery/*/celery/macro.app.html) macro:

```rust,no_run,noplaypen
# use celery::TaskResult;
# #[celery::task]
# fn add(x: i32, y: i32) -> TaskResult<i32> {
#     Ok(x + y)
# }
let my_app = celery::app!(
    broker = AMQP { std::env::var("AMQP_ADDR").unwrap() },
    tasks = [add],
    task_routes = [],
);
```

The Celery app can be used as either a producer or consumer (worker). To send tasks to a
queue for a worker to consume, use the [`Celery::send_task`](https://docs.rs/celery/*/celery/struct.Celery.html#method.send_task) method:

```rust,no_run,noplaypen
# use celery::TaskResult;
# #[celery::task]
# fn add(x: i32, y: i32) -> TaskResult<i32> {
#     Ok(x + y)
# }
# #[tokio::main]
# async fn main() -> Result<(), exitfailure::ExitFailure> {
# let my_app = celery::app!(
#     broker = AMQP { std::env::var("AMQP_ADDR").unwrap() },
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
# use celery::TaskResult;
# #[celery::task]
# fn add(x: i32, y: i32) -> TaskResult<i32> {
#     Ok(x + y)
# }
# #[tokio::main]
# async fn main() -> Result<(), exitfailure::ExitFailure> {
# let my_app = celery::app!(
#     broker = AMQP { std::env::var("AMQP_ADDR").unwrap() },
#     tasks = [add],
#     task_routes = [],
# );
my_app.consume().await?;
# Ok(())
# }
```

<br/>
<br/>

A full working example is provided in the [`examples/`](https://github.com/rusty-celery/rusty-celery/tree/master/examples) directory on GitHub. The includes a Celery app implemented in both Rust and Python with an AMQP broker. The only mandatory system requirement other than Rust is Docker, which is needed to run a RabbitMQ instance for the broker.

To play with the example, first clone the repository:

```bash
git clone https://github.com/rusty-celery/rusty-celery && cd rusty-celery
```

Then start the RabbitMQ instance:

```bash
./scripts/brokers/amqp.sh
```

Once the RabbitMQ Docker container has loaded, you can run a Rust worker in a separate terminal with


```bash
cargo run --example celery_app consume
```

From another terminal you can then send tasks to the worker from Rust with

```bash
cargo run --example celery_app produce
```

If you have Python and the [celery](http://www.celeryproject.org/) Python library installed, you can also produce tasks from the Python app with

```bash
python examples/celery_app.py
```

Or run a Python worker with

```bash
celery --app=celery_app.my_app worker --workdir=examples --loglevel=info
```
