FROM gliderlabs/alpine:3.1

MAINTAINER Mitch Dempsey <mitch@mitchdempsey.com>

RUN apk --update add \
    bash \
    curl \
    jq \
    py-pip \
    && pip install awscli

RUN mkdir -p /output

VOLUME ["/output"]

COPY dynamodb_to_envfile.sh /dynamodb_to_envfile.sh

ENTRYPOINT ["/bin/bash"]

CMD ["/dynamodb_to_envfile.sh"]
