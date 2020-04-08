# Best practices

## Acks early vs acks late

Tasks are only removed from a queue when they are acknowledged ("acked") by the worker that received them. The [`acks_late`](https://docs.rs/celery/*/celery/struct.CeleryBuilder.html#method.acks_late) setting determines when a worker will ack a task. When set to `true`, tasks are acked after the worker finishes executing them. When set to `false`, they are executed right before the worker starts executing them.

The default of `acks_late` is `false`, however if your tasks are [idempotent](https://docs.celeryproject.org/en/stable/glossary.html#term-idempotent) it's strongly recommended that you set `acks_late` to `true`. This has two major benefits.

First, it ensures that if a worker were to crash, any tasks currently executing will be retried automatically by the next available worker.

Second, it provides a better [back pressure](https://medium.com/@jayphelps/backpressure-explained-the-flow-of-data-through-software-2350b3e77ce7) mechanism when used in conjunction with a suitable [`prefetch_count`](https://docs.rs/celery/*/celery/struct.CeleryBuilder.html#method.prefetch_count) (see below).

## Prefetch count

When initializing your Rust Celery app it's recommended that you [set the `prefetch_count`](https://docs.rs/celery/*/celery/macro.app.html#optional-parameters) to a number suitable for your application, especially if you have `acks_late` set to `true`.

> If you have `acks_late` set to `false`, the default `prefetch_count` is probably sufficient.

The `prefetch_count` determines how many un-acked tasks (ignoring those with a future ETA) that a worker can hold onto at any point in time. Having `prefetch_count` too low or too high can create a bottleneck.

If the number is set too low, workers could be under-utilized. If the number is set too high, workers could be hogging tasks that they can't execute yet, or worse: they could run out of memory from receiving too many tasks and crash.

Unfortunately finding an optimal prefetch count is easier said than done. It depends on a lot of factors, such as the hardware your workers are running on, the task throughput, and whether your tasks are more CPU-bound or IO-bound.

The last reason is especially important. A worker running on even a single CPU can probably handle hundreds, if not thousands, of (non-blocking) IO-bound tasks at once. But a worker consuming CPU-bound tasks is essentially limited to executing one task per CPU core. Therefore a good starting point for `prefetch_count` would be either `100 x NUM_CPUS` for IO-bound tasks or `2 * NUM_CPUS` for CPU-bound tasks.

## Consuming blocking / CPU-bound tasks

If your tasks are CPU-bound (or otherwise blocking), it's recommended that you use a multi-threaded async runtime, such as [the one](https://docs.rs/tokio/0.2.16/tokio/runtime/index.html#threaded-scheduler) provided by `tokio`. Within the task body you can then call [`tokio::task::block_in_place`](https://docs.rs/tokio/0.2.16/tokio/task/index.html#block_in_place) where appropriate.
