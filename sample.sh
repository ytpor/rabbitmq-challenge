#!/bin/bash
# Sample script that will create exchange and queue

jq_not_installed() { echo "jq not installed" 1>&2; exit 1; }

not_found() { local COMMENT="$1"; echo "${COMMENT} not found" 1>&2; exit 1; }

# Load environment variables from .env file
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
    not_found ".env"
fi

HOST=http://localhost:${RABBITMQ_UI_PORT}
BASIC_AUTH=${RABBITMQ_USERNAME}:${RABBITMQ_PASSWORD}

check_status_code() {
    local COMMENT="$1"
    local STATUS_CODE="$2"

    if [[ "${STATUS_CODE}" == "201" ]]; then
        echo "✅ ${COMMENT} created successfully."
    elif [[ "${STATUS_CODE}" == "204" ]]; then
        echo "📌 ${COMMENT} already exists."
    else
        echo "❌ Failed to create ${COMMENT}. HTTP status: ${STATUS_CODE}"
        exit 1
    fi
}

add_vhost() {
    local MY_VHOST="$1"
    local STATUS_CODE

    STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" -u ${BASIC_AUTH} \
        -X PUT "${HOST}/api/vhosts/${MY_VHOST}")

    check_status_code "Virtual Host" ${STATUS_CODE}
}

create_user() {
    local MY_USER="$1"
    local MY_PASSWORD="$2"
    local STATUS_CODE

    STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" -u ${BASIC_AUTH} \
        -X PUT "${HOST}/api/users/${MY_USER}" \
        -H "Content-Type: application/json" \
        -d "{\"password\":\"${MY_PASSWORD}\",\"tags\":\"\"}")

    check_status_code "User ${MY_USER}" ${STATUS_CODE}
}

set_permission() {
    local MY_VHOST="$1"
    local MY_USER="$2"
    local STATUS_CODE

    STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" -u ${BASIC_AUTH} \
        -X PUT "${HOST}/api/permissions/${MY_VHOST}/${MY_USER}" \
        -H "Content-Type: application/json" \
        -d '{
            "configure":".*",
            "write":".*",
            "read":".*"
        }')

    check_status_code "Permission ${MY_VHOST}/${MY_USER}" ${STATUS_CODE}
}

declare_exchange() {
    local MY_VHOST="$1"
    local MY_EXCHANGE="$2"
    local STATUS_CODE

    STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" -u ${BASIC_AUTH} \
        -X PUT "${HOST}/api/exchanges/${MY_VHOST}/${MY_EXCHANGE}" \
        -H "Content-Type: application/json" \
        -d '{
            "type": "topic",
            "durable": true
        }')

    check_status_code "Exchange ${MY_EXCHANGE} in ${MY_VHOST}" ${STATUS_CODE}
}

create_queue() {
    local MY_VHOST="$1"
    local MY_QUEUE="$2"
    local STATUS_CODE

    STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" -u ${BASIC_AUTH} \
        -X PUT "${HOST}/api/queues/${MY_VHOST}/${MY_QUEUE}" \
        -H "Content-Type: application/json" \
        -d '{
            "durable": true
        }')

    check_status_code "Queue ${MY_QUEUE} in ${MY_VHOST}" ${STATUS_CODE}
}

bind_queue() {
    local MY_VHOST="$1"
    local MY_EXCHANGE="$2"
    local MY_QUEUE="$3"
    local ROUTING_KEY="$4"
    local STATUS_CODE

    STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" -u ${BASIC_AUTH} \
        -X POST "${HOST}/api/bindings/${MY_VHOST}/e/${MY_EXCHANGE}/q/${MY_QUEUE}" \
        -H "Content-Type: application/json" \
        -d "{
            \"routing_key\": \"${ROUTING_KEY}\",
            \"arguments\": {}
        }")

    check_status_code "Bind ${MY_QUEUE} to ${MY_EXCHANGE}" ${STATUS_CODE}
}

main() {
    add_vhost ${RABBITMQ_VHOST}
    create_user ${RABBITMQ_TEST_USER} ${RABBITMQ_TEST_USER_PWD}
    set_permission ${RABBITMQ_VHOST} ${RABBITMQ_USERNAME}
    set_permission ${RABBITMQ_VHOST} ${RABBITMQ_TEST_USER}
    declare_exchange ${RABBITMQ_VHOST} ${RABBITMQ_EXCHANGE}
    create_queue ${RABBITMQ_VHOST} ${RABBITMQ_QUEUE_CATEGORY}
    create_queue ${RABBITMQ_VHOST} ${RABBITMQ_QUEUE_ITEM_ATTRIBUTE}
    bind_queue ${RABBITMQ_VHOST} ${RABBITMQ_EXCHANGE} ${RABBITMQ_QUEUE_CATEGORY} ${RABBITMQ_QUEUE_CATEGORY_KEY}
    bind_queue ${RABBITMQ_VHOST} ${RABBITMQ_EXCHANGE} ${RABBITMQ_QUEUE_ITEM_ATTRIBUTE} ${RABBITMQ_QUEUE_ITEM_ATTRIBUTE_KEY}
}

# Run the script
main
