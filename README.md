
# RabbitMQ Challenge

RabbitMQ runs within `Docker` that is used for application development.

## Assumption

* You are running within the `docker` network `nginx-proxy`.

## Configuration

Make a copy of `.env.example`, and name it `.env`. Update the configuration accordingly.

## Setup

Build the RabbitMQ container, and start an instance.

    docker-compose up -d

You can then access the Management UI through the following URL:

    http://127.0.0.1:15672


You can access the RabbitMQ Management HTTP API through the following URL:

    http://127.0.0.1:15672/api/index.html

## Usage

From within the `nginx-proxy` network, other containers can access RabbitMQ by its container name `rabbitmq`.

## Access control

Only users with the `administrator` tag can access the management plugin (UI, HTTP API) through the UI port, eg. `http://127.0.0.1:15672`

## Logs

You can follow the latest RabbitMQ log using the command below:

    docker logs --tail 10 -f rabbitmq

## Example

Create virtual host `myapp.vhost`

    docker-compose exec rabbitmq rabbitmqctl add_vhost myapp.vhost

Allow administrator user `development` to access the virtual host

    docker-compose exec rabbitmq rabbitmqctl \
        set_permissions -p myapp.vhost development "^myapp.*" "^myapp.*" "^myapp.*"

Create user `myapp_user` and set permission to access virtual host

    docker-compose exec rabbitmq rabbitmqctl \
        add_user myapp_user strongpassword

    docker-compose exec rabbitmq rabbitmqctl \
        set_permissions -p myapp.vhost myapp_user "^myapp.*" "^myapp.*" "^myapp.*"

    docker-compose exec rabbitmq rabbitmqctl \
        list_permissions -p myapp.vhost

**NOTE** For the next 3 steps, only user, eg. `development`, with the correct permission can run them.

Declare a topic exchange

    docker-compose exec rabbitmq rabbitmqadmin \
        -u development -p Wjvm5lIWk4sKkEcO --vhost=myapp.vhost \
        declare exchange name=myapp.topic.exchange type=topic durable=true

Create the Queues.

    docker-compose exec rabbitmq rabbitmqadmin \
        -u development -p Wjvm5lIWk4sKkEcO -V myapp.vhost \
        declare queue name=myapp.queue-foo durable=true

    docker-compose exec rabbitmq rabbitmqadmin \
        -u development -p Wjvm5lIWk4sKkEcO -V myapp.vhost \
        declare queue name=myapp.queue-bar durable=true

Bind Queues to Exchange.

    docker-compose exec rabbitmq rabbitmqadmin \
        -u development -p Wjvm5lIWk4sKkEcO -V myapp.vhost \
        declare binding source=myapp.topic.exchange destination_type=queue \
        destination=myapp.queue-foo routing_key=myapp.queue-foo

    docker-compose exec rabbitmq rabbitmqadmin \
        -u development -p Wjvm5lIWk4sKkEcO -V myapp.vhost \
        declare binding source=myapp.topic.exchange destination_type=queue \
        destination=myapp.queue-bar routing_key=myapp.queue-bar

Verify binding

    docker-compose exec rabbitmq rabbitmqadmin \
        -u development -p Wjvm5lIWk4sKkEcO -V myapp.vhost \
        list queues

    docker-compose exec rabbitmq rabbitmqadmin \
        -u development -p Wjvm5lIWk4sKkEcO -V myapp.vhost \
        list bindings

