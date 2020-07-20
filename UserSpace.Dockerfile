FROM docker.io/node:12 AS ui
WORKDIR /ui
COPY ui/package.json ui/package-lock.json /ui/
RUN npm install
COPY ui .
RUN npm run build

FROM docker.io/golang:1.14 AS build
WORKDIR /wg
RUN go get github.com/go-bindata/go-bindata/...
RUN go get github.com/elazarl/go-bindata-assetfs/...
COPY go.mod .
COPY go.sum .
RUN go mod download
COPY . .
COPY --from=ui /ui/dist ui/dist
RUN go-bindata-assetfs -prefix ui/dist ui/dist
RUN go install .

FROM golang AS go_build
WORKDIR /wg-go
RUN git clone https://git.zx2c4.com/wireguard-go && cd wireguard-go && make

FROM gcr.io/distroless/base
COPY --from=build /go/bin/wireguard-ui /
COPY --from=go_build /wg-go/wireguard-go /
ENTRYPOINT [ "/wireguard-ui" ]
