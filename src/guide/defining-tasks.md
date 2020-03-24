# Defining Tasks

A **task** represents a unit of work that a `Celery` app can produce or consume.

The recommended way to define a task is by decorating a function with the [`task`](https://docs.rs/celery/*/celery/attr.task.html) attribute macro:

```rust,noplaypen
use celery::TaskResult;

#[celery::task]
fn add(x: i32, y: i32) -> TaskResult<i32> {
    Ok(x + y)
}
```

If the function has a return value the return type must be a [`TaskResult<T>`](https://docs.rs/celery/*/celery/task/type.TaskResult.html).

Under the hood a task is just a struct that implements the [`Task`](https://docs.rs/celery/*/celery/task/trait.Task.html) trait. When you decorate a function with the task macro, this creates a struct and implements the `Task` trait so that [`Task::run`](https://docs.rs/celery/*/celery/task/trait.Task.html#method.run) calls the function you've defined.

The macro accepts a number of [optional parameters](https://docs.rs/celery/*/celery/attr.task.html#parameters).

For example, to give a task a custom name and set a timeout:

```rust,noplaypen
use tokio::time::{self, Duration};

#[celery::task(name = "sleep", timeout = 5)]
async fn delay(secs: u64) {
    time::delay_for(Duration::from_secs(secs)).await;
}
```

## Error handling

When a task executes, i.e. when the `Task::run` method is called, it returns a [`TaskResult<T>`](https://docs.rs/celery/*/celery/task/type.TaskResult.html) which is just a `Result<T, TaskError>`. When an `Err(TaskError)` is returned, the worker considers the task failed and may send it back to the broker to be retried.

A worker treats certain [`TaskError`](https://docs.rs/celery/*/celery/error/enum.TaskError.html) variants differently. So when your task has points of failure, such as in the `read_some_file` example below, you'll need to coerce those possible error types to the appropriate `TaskError` variant and propogate them upwards:

```rust,noplaypen
use celery::{TaskResult, TaskResultExt};

#[celery::task]
async fn read_some_file() -> TaskResult<String> {
    tokio::fs::read_to_string("some_file")
        .await
        .with_unexpected_err("File does not exist")
}
```

Here `tokio::fs::read_to_string("some_file").await` produces a [tokio::io::Result](`https://docs.rs/tokio/0.2.13/tokio/io/type.Result.html`), so we use the helper method `.with_unexpected_err` from the [`TaskResultExt`](https://docs.rs/celery/*/celery/error/trait.TaskResultExt.html) trait to convert this into a `TaskError::UnexpectedError` and then apply the [`?`](https://doc.rust-lang.org/book/ch09-02-recoverable-errors-with-result.html#propagating-errors) operator to propogate it upwards.

There are two error kinds in particular that are meant as catch-alls for any other type of error that could arise in your task: [`TaskError::UnexpectedError`](https://docs.rs/celery/*/celery/error/enum.TaskError.html#variant.UnexpectedError) and [`TaskError::ExpectedError`](https://docs.rs/celery/*/celery/error/enum.TaskError.html#variant.ExpectedError). The latter should be used for errors that will occasionally happen due to factors outside of your control - such as a third party service being temporarily unavailable - while `UnexpectedError` should be reserved to indicate a bug or that a critical resource is missing.

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
    time::delay_for(Duration::from_secs(secs)).await;
}
```

So you could call this task from Python with or without providing a value for `secs`:

```python,noplaypen
celery_app.send_task("sleep", args=[10])
celery_app.send_task("sleep")
```

## Callbacks

You can set custom callbacks to run when a task fails or succeeds through the `on_failure` and `on_success` options to the `task` macro:

```rust,noplaypen
use celery::task::Task;
use celery::error::TaskError;
use tokio::time::{self, Duration};

#[celery::task(
    timeout = 10,
    on_failure = failure_callback,
    on_success = success_callback,
)]
async fn sleep(secs: u64) {
    time::delay_for(Duration::from_secs(secs)).await;
}

async fn failure_callback<T: Task>(task: &T, err: &TaskError) {
    match err {
        TaskError::TimeoutError => println!("Oops! Task {} timed out!", task.name()),
        _ => println!("Hmm task {} failed with {:?}", task.name(), err),
    };
}

async fn success_callback<T: Task>(task: &T, _ret: &T::Returns) {
    println!("{} succeeded!", task.name());
}
```

## Summary

In summary, tasks are easily defined by decorating a function with the `#[celery::task]` macro. If the function returns anything the return type has to be a `TaskResult<T>`. Internally the function is wrapped in a struct that implements the `Task` trait.

The quickest way to propogate expected or unexpected errors from within your task is by using `.with_expected_err("...")?` or `.with_unexpected_err("...")?`,  respectively, on the `Result`.
