FROM golang:1.25-alpine AS build
RUN apk add --no-cache git ca-certificates
RUN git clone --depth 1 --branch RELEASE.2025-10-15T17-29-55Z https://github.com/minio/minio.git /source
WORKDIR /source
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /minio .
FROM alpine:3.22
RUN apk add --no-cache ca-certificates && adduser -D -u 10001 miar && mkdir /data && chown miar /data
COPY --from=build /minio /usr/local/bin/minio
USER miar
EXPOSE 9000
ENTRYPOINT ["minio"]
