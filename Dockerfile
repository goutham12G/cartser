
FROM mcr.microsoft.com/dotnet/sdk:5.0.102-ca-patch-buster-slim as builder
WORKDIR /app

COPY cartservice.csproj .

RUN dotnet restore cartservice.csproj -r linux-musl-x64

COPY . .
# can't use single-file mode
RUN dotnet publish cartservice.csproj -r linux-musl-x64 --self-contained true -p:PublishTrimmed=True -p:TrimMode=Link -c release -o /cartservice --no-restore

# https://mcr.microsoft.com/v2/dotnet/runtime-deps/tags/list
FROM mcr.microsoft.com/dotnet/runtime-deps:5.0.1-alpine3.12-amd64
RUN GRPC_HEALTH_PROBE_VERSION=v0.3.6 && \
    wget -qO/bin/grpc_health_probe https://github.com/grpc-ecosystem/grpc-health-probe/releases/download/${GRPC_HEALTH_PROBE_VERSION}/grpc_health_probe-linux-amd64 && \
    chmod +x /bin/grpc_health_probe
WORKDIR /app

# https://github.com/grpc/grpc/issues/21446
RUN echo 'http://dl-cdn.alpinelinux.org/alpine/v3.8/main' >> /etc/apk/repositories && \
    apk update --no-cache && \
    apk add --no-cache bash libc6-compat=1.1.19-r11

COPY --from=builder /cartservice .
ENV ASPNETCORE_URLS http://*:7070
ENTRYPOINT ["/app/cartservice"]
