module metachat/matching-service

go 1.21

require (
	github.com/gorilla/mux v1.8.1
	github.com/google/uuid v1.4.0
	github.com/confluentinc/confluent-kafka-go/v2 v2.3.0
	github.com/gocql/gocql v1.5.0
	github.com/go-playground/validator/v10 v10.15.5
	github.com/golang/protobuf v1.5.3
	google.golang.org/grpc v1.60.1
	google.golang.org/protobuf v1.31.0
	github.com/sirupsen/logrus v1.9.3
	github.com/spf13/viper v1.17.0
	
	metachat/common/event-sourcing v0.0.0
)

replace metachat/common/event-sourcing => ../../common/event-sourcing

require (
	github.com/cespare/xxhash/v2 v2.2.0 // indirect
	github.com/davecgh/go-spew v1.1.1 // indirect
	github.com/golang/snappy v0.0.1 // indirect
	github.com/hailocab/go-hostpool v0.0.0-20160125115350-e80d13ce29ed // indirect
	github.com/pmezard/go-difflib v1.0.0 // indirect
	github.com/stretchr/testify v1.8.4 // indirect
	github.com/twmb/go-enum v0.0.0-20180419042959-7903375b9ab4 // indirect
	golang.org/x/net v0.17.0 // indirect
	golang.org/x/sys v0.13.0 // indirect
	golang.org/x/text v0.13.0 // indirect
	google.golang.org/genproto/googleapis/rpc v0.0.0-20231212172506-995d672761c0 // indirect
	gopkg.in/yaml.v3 v3.0.1 // indirect
)