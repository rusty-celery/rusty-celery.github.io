<div align="center">
    <br>
    <img src="https://raw.githubusercontent.com/rusty-celery/rusty-celery/master/img/rusty-celery-logo-transparent.png"/>
    <br>
    <br>
    <p>
    A Rust implementation of <a href="https://github.com/celery/celery">Celery</a> for producing and consuming asyncronous tasks with a distributed message queue.
    </p>
    <hr/>
</div>
<p align="center">
    <a href="https://github.com/rusty-celery/rusty-celery/actions">
        <img alt="Build" src="https://github.com/rusty-celery/rusty-celery/workflows/CI/badge.svg?event=push&branch=master">
    </a>
    <a href="https://github.com/rusty-celery/rusty-celery/blob/master/LICENSE">
        <img alt="License" src="https://img.shields.io/github/license/rusty-celery/rusty-celery.svg?color=blue&cachedrop">
    </a>
    <a href="https://crates.io/crates/celery">
        <img alt="Crates" src="https://img.shields.io/crates/v/celery.svg?color=blue">
    </a>
    <a href="https://docs.rs/celery/">
        <img alt="Docs" src="https://img.shields.io/badge/docs.rs-API%20docs-blue">
    </a>
    <a href="https://github.com/rusty-celery/rusty-celery/issues?q=is%3Aissue+is%3Aopen+label%3A%22Status%3A+Help+Wanted%22">
        <img alt="Help wanted" src="https://img.shields.io/github/issues/rusty-celery/rusty-celery/Status%3A%20Help%20Wanted?label=Help%20Wanted">
    </a>
    <a href="https://discord.gg/PV3azbB">
        <img alt="Discord" src="https://img.shields.io/discord/689533070247723078?logo=discord">
    </a>
</p>
<br/>


# What is Rusty Celery?

Simply put, this is a Rust implementation of the [Celery](https://docs.celeryq.dev/) protocol for producing and consuming asyncronous tasks with a distributed message broker.
It comes with an idiomatic async API driven by the performant [tokio.rs](https://tokio.rs/), and above all an emphasis on safety.

### How does it work?

Celery revolves around the concept of a **task**. A task is a unit of work that is requested by a producer to be completed by a consumer / worker.

For example, a social media service may need tasks to notify a user's followers when they post new content. When a user uploads their content to the service's website, the website's backend would act as the producer sending out the tasks to a set of workers - usually deployed on a separate server or cluster - via a distributed message broker.

A [`Celery`](https://docs.rs/celery/*/celery/struct.Celery.html) application instance is meant to serve as either the producer or the consumer. In this example, both the website backend and the worker applications would initialize a `Celery` app in the same way, with the exact same configuration. The web backend would then call [`Celery::send_task`](https://docs.rs/celery/*/celery/struct.Celery.html#method.send_task) to produce a task which a worker would receive while it is consuming tasks through the [`Celery::consume`](https://docs.rs/celery/*/celery/struct.Celery.html#method.consume) method.

### Built to scale

The Celery framework is a multiple producer, multiple consumer setup: any number of producer applications can send tasks to any number of workers. Naturally this allows seamless horizontal scaling.

### What do I need?

The [`Broker`](https://docs.rs/celery/*/celery/broker/trait.Broker.html) is an integral part in all of this, providing the channel through which producers communicate to consumers and distributing tasks among the available workers. As of writing this, the only officially supported broker is the [`AMQPBroker`](https://docs.rs/celery/*/celery/broker/struct.AMQPBroker.html) which can be used with a [RabbitMQ](https://www.rabbitmq.com/) instance. The RabbitMQ instance would be the actual **broker**, while the `AMQPBroker` struct provides the API that the `Celery` app uses to communicate with it.

There are many RabbitMQ hosting services available, such as [CloudAMQP](https://www.cloudamqp.com/) and [Compose](https://www.compose.com/databases/rabbitmq). Both of these have free tier options for development purposes.

<br/>
<br/>

---

Rusty Celery is [developed on GitHub](https://github.com/rusty-celery) as an open source community effort.

[![](https://sourcerer.io/fame/epwalsh/rusty-celery/rusty-celery/images/0)](https://sourcerer.io/fame/epwalsh/rusty-celery/rusty-celery/links/0)[![](https://sourcerer.io/fame/epwalsh/rusty-celery/rusty-celery/images/1)](https://sourcerer.io/fame/epwalsh/rusty-celery/rusty-celery/links/1)[![](https://sourcerer.io/fame/epwalsh/rusty-celery/rusty-celery/images/2)](https://sourcerer.io/fame/epwalsh/rusty-celery/rusty-celery/links/2)[![](https://sourcerer.io/fame/epwalsh/rusty-celery/rusty-celery/images/3)](https://sourcerer.io/fame/epwalsh/rusty-celery/rusty-celery/links/3)[![](https://sourcerer.io/fame/epwalsh/rusty-celery/rusty-celery/images/4)](https://sourcerer.io/fame/epwalsh/rusty-celery/rusty-celery/links/4)[![](https://sourcerer.io/fame/epwalsh/rusty-celery/rusty-celery/images/5)](https://sourcerer.io/fame/epwalsh/rusty-celery/rusty-celery/links/5)[![](https://sourcerer.io/fame/epwalsh/rusty-celery/rusty-celery/images/6)](https://sourcerer.io/fame/epwalsh/rusty-celery/rusty-celery/links/6)[![](https://sourcerer.io/fame/epwalsh/rusty-celery/rusty-celery/images/7)](https://sourcerer.io/fame/epwalsh/rusty-celery/rusty-celery/links/7)
