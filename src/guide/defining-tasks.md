# Defining Tasks

A **task** represents a unit of work that a `Celery` app can produce or consume.

The recommended way to define a task is by decorating a function with the [`task`](https://docs.rs/celery/*/celery/attr.task.html) attribute macro:

```rust,noplaypen
use celery::task;

#[task]
fn add(x: i32, y: i32) -> i32 {
    x + y
}
```

The macro accepts the following optional parameters:

- `name`: The name to use when registering the task. Should be unique. If not given the name
will be set to the name of the function being decorated.
- `timeout`: Corresponds to [`Task::timeout`](https://docs.rs/celery/*/celery/trait.Task.html#method.timeout).
- `max_retries`: Corresponds to [`Task::max_retries`](https://docs.rs/celery/*/celery/trait.Task.html#method.max_retries).
- `min_retry_delay`: Corresponds to [`Task::min_retry_delay`](https://docs.rs/celery/*/celery/trait.Task.html#method.min_retry_delay).
- `max_retry_delay`: Corresponds to [`Task::max_retry_delay`](https://docs.rs/celery/*/celery/trait.Task.html#method.max_retry_delay).

For example, to give a task a custom name and set a timeout:

```rust,noplaypen
# use celery::task;
use tokio::time::{self, Duration};

#[task(name = "sleep", timeout = 5)]
fn delay(secs: u64) {
    time::delay_for(Duration::from_secs(secs)).await
}
```

## Error handling

As demonstrated below in [Implementation details](#implementation-details), the `#[task]` attribute macro will wrap the return value
of the function in `Result<Self::Returns, Error>`.
Therefore the recommended way to propogate errors when defining a task is to use
`.context("...")?` on `Result` types within the task body:

```rust,noplaypen
use celery::{task, ResultExt};

#[task]
fn read_some_file() -> String {
    tokio::fs::read_to_string("some_file")
        .await
        .context("File does not exist")?
}
```

The `.context` method on a `Result` comes from the [`ResultExt`](https://docs.rs/celery/*/celery/trait.ResultExt.html) trait.
This is used to provide additional human-readable context to the error and also
to convert it into the expected [`Error`](https://docs.rs/celery/*/celery/struct.Error.html) type.

## Positional vs keyword parameters

Within the [Celery protocol](https://docs.celeryproject.org/en/latest/internals/protocol.html#version-2)
task parameters can be treated as either `args` (positional) or `kwargs` (key-word based).
Both are supported in Rusty Celery, which means you could call the Rust `add` task defined above from another language like Python in any of the following ways:

```python,noplaypen
celery_app.send_task("add", args=[1, 2])
celery_app.send_task("add", kwargs={"x": 1, "y": 2})
celery_app.send_task("add", args=[1], kwargs={"y": 2})
```

## Optional parameters

Any parameters that are [`Option<T>`](https://doc.rust-lang.org/stable/std/option/enum.Option.html) types are automatically treated as optional with a default value of `None`. For example

```rust,noplaypen
# use celery::task;
use tokio::time::{self, Duration};

#[task]
fn delay(secs: Option<u64>) {
    let secs = secs.unwrap_or(10);
    time::delay_for(Duration::from_secs(secs)).await
}
```

So you could call this task from Python with or without providing a value for `secs`:

```python,noplaypen
celery_app.send_task("sleep", args=[10])
celery_app.send_task("sleep")
```

## Implementation details

Under the hood a task is just a struct that implements the [`Task`](https://docs.rs/celery/*/celery/trait.Task.html) trait. The `#[task]` proc macro inspects the
function it is decorating and creates a struct with fields matching the function arguments and
then provides an implementation of the `Task` trait where the [`Task::run`](https://docs.rs/celery/*/celery/trait.Task.html#method.run) method
is the body of the function.

The `add` task from above essentially expands out to this:

```rust,noplaypen
use async_trait::async_trait;
use serde::{Serialize, Deserialize};
use celery::{Task, Error};

#[allow(non_camel_case_types)]
#[derive(Serialize, Deserialize)]
struct add {
    x: i32,
    y: i32,
}

impl add {
    fn new(x: i32, y: i32) -> Self {
        Self { x, y }
    }
}

#[async_trait]
impl Task for add {
    const NAME: &'static str = "add";
    const ARGS: &'static [&'static str] = &["x", "y"];

    type Returns = i32;

    async fn run(mut self) -> Result<Self::Returns, Error> {
        Ok(self.x + self.y)
    }
}
```
