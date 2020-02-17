# Defining Tasks

A **task** represents a unit of work that a `Celery` app can produce or consume.

The recommended way to define a task is by decorating a function with the [`task`](https://docs.rs/celery/*/celery/attr.task.html) attribute macro:

```rust,noplaypen
#[celery::task]
fn add(x: i32, y: i32) -> i32 {
    x + y
}
```

The macro accepts the following optional parameters:

- `name`: The name to use when registering the task. Should be unique. If not given the name
will be set to the name of the function being decorated.
- `timeout`: Corresponds to [`Task::timeout`](https://docs.rs/celery/*/celery/task/trait.Task.html#method.timeout).
- `max_retries`: Corresponds to [`Task::max_retries`](https://docs.rs/celery/*/celery/task/trait.Task.html#method.max_retries).
- `min_retry_delay`: Corresponds to [`Task::min_retry_delay`](https://docs.rs/celery/*/celery/task/trait.Task.html#method.min_retry_delay).
- `max_retry_delay`: Corresponds to [`Task::max_retry_delay`](https://docs.rs/celery/*/celery/task/trait.Task.html#method.max_retry_delay).

For example, to give a task a custom name and set a timeout:

```rust,noplaypen
use tokio::time::{self, Duration};

#[celery::task(name = "sleep", timeout = 5)]
async fn delay(secs: u64) {
    time::delay_for(Duration::from_secs(secs)).await
}
```

> 💡 In this example the `delay` function was marked `async`, but it actually would have compiled without `async` as well because internally tasks are always run as async functions.

## Error handling

As demonstrated below in [Implementation details](#implementation-details), the `#[celery::task]` attribute macro will wrap the return value
of the function in a `Result<T, celery::error::TaskError>`, where `T` is whatever type the function you define returns (like `i32` in the `add` task above).

As a consequence you'll have to coerce any errors that could occur in your task to a [`TaskError`](https://docs.rs/celery/*/celery/error/enum.TaskError.html) with the right variant and then propogate those errors upwards using the [`?`](https://doc.rust-lang.org/book/ch09-02-recoverable-errors-with-result.html#propagating-errors) operator.

There are two error kinds in particular that are meant as catch-alls for any other type of error that could arise in your task: [`TaskError::UnexpectedError`](https://docs.rs/celery/*/celery/error/enum.TaskError.html#variant.UnexpectedError) and [`TaskError::ExpectedError`](https://docs.rs/celery/*/celery/error/enum.TaskError.html#variant.ExpectedError). The latter should be used for errors that will occasionally happen due to factors outside of your control - such as a third party service being temporarily unavailable - while `UnexpectedError` should be reserved to indicate a bug or that a critical resource is missing.

One way to convert into either of those is by using [`.map_err`](https://doc.rust-lang.org/std/result/enum.Result.html#method.map_err). There are also shortcuts for converting to an `ExpectedError` or `UnexpectedError` that come from the [`TaskResultExt`](https://docs.rs/celery/*/celery/error/trait.TaskResultExt.html) trait. Namely, the `.with_expected_err` and `.with_unexpected_err` methods. This followed by the `?` operator is the recommended way to propogate an `UnexpectedError`:

```rust,noplaypen
use celery::error::TaskResultExt;

#[celery::task]
async fn read_some_file() -> String {
    tokio::fs::read_to_string("some_file")
        .await
        .with_unexpected_err("File does not exist")?
}
```

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
use tokio::time::{self, Duration};

#[celery::task]
async fn delay(secs: Option<u64>) {
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

Under the hood a task is just a struct that implements the [`Task`](https://docs.rs/celery/*/celery/task/trait.Task.html) trait. The `#[celery::task]` proc macro inspects the
function it is decorating and creates a struct with fields matching the function arguments and
then provides an implementation of the `Task` trait where the [`Task::run`](https://docs.rs/celery/*/celery/task/trait.Task.html#method.run) method
is just a wrapper around the body of the function you wrote.

The `add` task from above essentially expands out to this:

```rust,noplaypen
use async_trait::async_trait;
use serde::{Serialize, Deserialize};
use celery::error::TaskError;
use celery::task::Task;

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

    async fn run(mut self) -> Result<Self::Returns, TaskError> {
        let x = self.x;
        let y = self.y;
        let result = {
            x + y  // this is the body of the actual function you wrote
        };
        Ok(result)
    }
}
```

## Summary

In summary, tasks are easily defined by decorating a function with the `#[celery::task]` macro. Internally the body of this function is wrapped in an async function and the return value is wrapped in a `Result<T, celery::error::TaskError>`. This makes it acceptable to use `.await` and `?` directly within your function.

The quickest way to propogate expected or unexpected errors from within your task is by using `.with_expected_err("...")?` or `.with_unexpected_err("...")?`,  respectively, on the `Result`.
