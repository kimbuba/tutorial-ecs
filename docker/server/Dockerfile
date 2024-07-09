# Build Stage
FROM golang:1.22.3-alpine3.19 AS BuildStage
MAINTAINER ecs-tutorial.ai

# Create appuser
ENV USER=my-docker-user
ENV UID=10001

RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    "${USER}"

WORKDIR /build

COPY build-source/ .

RUN go get -u ./... && go mod tidy

EXPOSE 8080

RUN go build -o /myapp cmd/myapp/myapp.go

# Deploy Stage
############################################################################
FROM gcr.io/distroless/cc-debian11

WORKDIR /

COPY --from=BuildStage /etc/passwd /etc/passwd
COPY --from=BuildStage /etc/group /etc/group
COPY --from=BuildStage /myapp /myapp

EXPOSE 8080

USER my-docker-user:my-docker-user
ENTRYPOINT ["/myapp"]