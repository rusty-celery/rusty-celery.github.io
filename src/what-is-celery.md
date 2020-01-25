# What is Rusty Celery?

Simply put, this is a Rust implementation of the [Celery](http://www.celeryproject.org/) protocol for producing and consuming asyncronous tasks with a distributed message broker.
It comes with an idiomatic async API driven by the performant [tokio.rs](https://tokio.rs/), and above all an emphasis on safety.

> Since Rusty Celery adheres to the Celery protocol, you can send tasks from a Python Celery application to a Rust worker or vice versa.

Rusty Celery is [developed on GitHub](https://github.com/rusty-celery) as an open source community effort and is backed by [Structurely](https://structurely.com/), a start-up building conversation AI.
