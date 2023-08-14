
FROM arm64v8/golang:latest AS builder


WORKDIR /rabbitmq


COPY . /rabbitmq/


RUN go mod download

WORKDIR /rabbitmq/consumer/
#RUN go build -o rabbitmqConsumer main.go 
#RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o rabbitmqConsumer .
RUN GOOS=linux GOARCH=arm64 go build -o rabbitmqConsumer .


FROM arm64v8/ubuntu:latest


WORKDIR /exec


COPY --from=builder /rabbitmq/consumer/rabbitmqConsumer .


CMD ["./rabbitmqConsumer"]
