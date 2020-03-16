# Best practices

## Acks early vs acks late

If you're familiar with Python Celery, [the answer](https://docs.celeryproject.org/en/stable/faq.html#should-i-use-retry-or-acks-late) of whether to set `acks_late` to `true` or `false` is the same: it depends.

The effect of acking late is that if a worker were to crash, any tasks that it's currently executing will be retried automatically by the next available worker. So if your tasks are [idempotent](https://docs.celeryproject.org/en/stable/glossary.html#term-idempotent) then it's recommended that you [set `acks_late` to `true`](https://docs.celeryproject.org/en/stable/glossary.html#term-idempotent). On the other hand, if retrying tasks that have potentially already executed could cause more damage than not retrying them, you should not ack late.

## Prefetch count

When initializing your Rust Celery app it's recommended that you [set the `prefetch_count`](https://docs.rs/celery/*/celery/macro.app.html#optional-parameters) to a number suitable for your application, especially if you have `acks_late` set to `true`.

> If you have `acks_late` set to `false`, the default `prefetch_count` is probably sufficient.

The `prefetch_count` determines how many un-acked tasks (ignoring those with a future ETA) that a worker can hold onto at any point in time. Having `prefetch_count` too low or too high can create a bottleneck.

If the number is set too low, workers could be under-utilized. If the number is set too high, workers could be hogging tasks that they can't execute yet.

Unfortunately finding an optimal prefetch count is easier said than done. It depends on a lot of factors, such as the hardware your workers are running on, the task throughput, and whether your tasks are more CPU-bound or IO-bound.

The last reason is especially important. A worker running on even a single CPU can probably handle hundreds, if not thousands, of (non-blocking) IO-bound tasks at once. But a worker consuming CPU-bound tasks is essentially limited to executing one task per CPU core. Therefore a good starting point for `prefetch_count` would be either `100 x NUM_CPUS` for IO-bound tasks or `m * NUM_CPUS` for CPU-bound tasks, where `m` is a small integer between 1 and 4.
