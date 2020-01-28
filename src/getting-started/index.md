# Getting started

### How does it work?

Celery revolves around the concept of a **task**. A task is a unit of work that is requested by a producer to be completed by a consumer / worker.

For example, a social media service may have tasks to notify a user's followers when they post new content. When the user uploads their content to the service's web application, the application acts as the producer sending out the tasks to a set of workers - usually deployed on a separate server or cluster - via a distributed message broker.

A [`Celery`](https://docs.rs/celery/*/celery/struct.Celery.html) application instance is meant to serve as either the producer or the consumer. In this example the web and worker applications would initialize a `Celery` app in the same way, with the exact same configuration. The web app would then call [`Celery::send_task`](https://docs.rs/celery/*/celery/struct.Celery.html#method.send_task) to produce a task which a worker would receive while it is consuming tasks through the [`Celery::consume`](https://docs.rs/celery/*/celery/struct.Celery.html#method.consume) method.

### Built to scale

The Celery framework is a multiple producer, multiple consumer setup: any number of producer applications can send tasks to any number of workers. Naturally this allows seamless horizontal scaling.

### What do I need?

The [`Broker`](https://docs.rs/celery/*/celery/trait.Broker.html) is an integral part in all of this, providing the channel through which producers communicate to consumers and distributing the tasks among the available workers. As of writing this, the only officially supported broker is the [`AMQPBroker`](https://docs.rs/celery/*/celery/struct.AMQPBroker.html) which can be used with a [RabbitMQ](https://www.rabbitmq.com/) instance. The RabbitMQ instance would be the actual **broker**, while the `AMQPBroker` struct provides the API that the `Celery` app uses to communicate with it.

There are many RabbitMQ hosting services available, such as [CloudAMQP](https://www.cloudamqp.com/) and [Compose](https://www.compose.com/databases/rabbitmq). Both of these have free tier options for development purposes.
