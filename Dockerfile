# Container image that runs your code
FROM alpine:3.15
MAINTAINER Darek <darek@platformos.com>

RUN apk add --update --no-cache curl

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]
