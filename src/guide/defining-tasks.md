# Defining Tasks

A **task** represents a unit of work that a `Celery` app can produce or consume.

The recommended way to define a task is by decorating a function with the [`task`](https://docs.rs/celery/*/celery/attr.task.html) attribute macro:

```rust,noplaypen
#[celery::task]
fn add(x: i32, y: i32) -> i32 {
    x + y
}
```

Under the hood a task is just a struct that implements the [`Task`](https://docs.rs/celery/*/celery/task/trait.Task.html) trait. When you decorate a function with the task macro, this creates a struct and implements the `Task` trait so that [`Task::run`](https://docs.rs/celery/*/celery/task/trait.Task.html#method.run) calls the function you've defined.

The macro accepts the following optional parameters:

- `name` (string literal): The name to use when registering the task. Should be unique. If not given the name
will be set to the name of the function being decorated.
- `timeout` (u32): The maximum number of seconds that the task is allowed to run. Note that this can only be enforced for tasks that are non-blocking, such as tasks that call async IO functions.
- `max_retries` (u32): The maximum number of times to retry the task if it fails.
- `min_retry_delay` (u32): The minimum number of seconds to wait before retrying after failure.
- `max_retry_delay` (u32): The maximum number of seconds to wait before retrying after failure.
- `acks_late` (bool): If true, the broker message corresponding to the task will be ackknowledged after the task finishes, instead of before.
- `bind` (bool): If true, the function will be bound to the task instance, i.e. it will be like an instance method. Therefore when `bind = true`, the first argument to the function has to have type `&Self`. Note however that Rust won't allow you to name this argument `self`, as that is a reserved keyword. Instead, use something like `task` or just `t`.

For example, to give a task a custom name and set a timeout:

```rust,noplaypen
use tokio::time::{self, Duration};

#[celery::task(name = "sleep", timeout = 5)]
async fn delay(secs: u64) {
    time::delay_for(Duration::from_secs(secs)).await
}
```

## Error handling

When a task executes, i.e. when the `Task::run` method is called, it returns a [`Result<T, TaskError>`](https://docs.rs/celery/*/celery/task/type.TaskResult.html) where `T` is whatever type the function you define returns (like `i32` in the `add` task above, or `()` in the `delay` task). So when the `add` task executes, an `Ok(i32)` will be returned.

The reason `Task::run` has to return a `Result` is so the worker executing the task can know when the task has failed. When an `Err(TaskError)` is returned, the worker considers the task failed and may send it back to the broker to be retried.

A worker will generally treat certain [`TaskError`](https://docs.rs/celery/*/celery/error/enum.TaskError.html) variants differently. So when your task has points of failure, such as in the `read_some_file` example below, you'll need to coerce those possible error types to the appropriate `TaskError` variant and propogate them upwards:

```rust,noplaypen
use celery::error::TaskResultExt;

#[celery::task]
async fn read_some_file() -> String {
    tokio::fs::read_to_string("some_file")
        .await
        .with_unexpected_err("File does not exist")?
}
```

Here `tokio::fs::read_to_string("some_file").await` produces a [tokio::io::Result](`https://docs.rs/tokio/0.2.13/tokio/io/type.Result.html`), so we use the helper method `.with_unexpected_err` from the [`TaskResultExt`](https://docs.rs/celery/*/celery/error/trait.TaskResultExt.html) trait to convert this into a `TaskError::UnexpectedError` and then apply the [`?`](https://doc.rust-lang.org/book/ch09-02-recoverable-errors-with-result.html#propagating-errors) operator to propogate it upwards.

> There are two error kinds in particular that are meant as catch-alls for any other type of error that could arise in your task: [`TaskError::UnexpectedError`](https://docs.rs/celery/*/celery/error/enum.TaskError.html#variant.UnexpectedError) and [`TaskError::ExpectedError`](https://docs.rs/celery/*/celery/error/enum.TaskError.html#variant.ExpectedError). The latter should be used for errors that will occasionally happen due to factors outside of your control - such as a third party service being temporarily unavailable - while `UnexpectedError` should be reserved to indicate a bug or that a critical resource is missing.

It's important to note that the return type of the `read_some_file` function is not a `Result` type. In fact, **the return type of the decorated function should never be a `Result` type.** The return type should always be the type that would result from a *successful* execution, and so your function should always return that bare type instead of an `Ok` or `Err`.

If you're familiar with the `?` operator, you may be wondering how we can use this within a function that is marked as returning `String` and not `Result<String, _>`. The reason this works is because the `task` attribute macro modifies the body of function by wrapping it in `Ok({ ... })` and changing the return type to a `Result`.

So in this example the `read_some_file` function is turned into something like this:

```rust,noplaypen
# use celery::error::{TaskResultExt, TaskError};
async fn read_some_file() -> Result<String, TaskError> {
    Ok({
        tokio::fs::read_to_string("some_file")
            .await
            .with_unexpected_err("File does not exist")?
    })
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

## Summary

In summary, tasks are easily defined by decorating a function with the `#[celery::task]` macro. Internally the function is wrapped in a struct that implements the `Task` trait, and the return value of the function is wrapped in a `Result<T, celery::error::TaskError>`. This makes it valid to use `?` directly within your function.

The quickest way to propogate expected or unexpected errors from within your task is by using `.with_expected_err("...")?` or `.with_unexpected_err("...")?`,  respectively, on the `Result`.
