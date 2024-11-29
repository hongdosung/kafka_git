curl --location --request POST 'http://localhost:8083/connectors' \
--header 'Content-Type: application/json' \
--data-raw '{
  "name": "source-test-connector",
  "config": {
    "connector.class": "io.debezium.connector.mysql.MySqlConnector",
    "tasks.max": "1",
    "database.hostname": "mysql",
    "database.port": "3306",
    "database.user": "mysqluser",
    "database.password": "mysqlpw",
    "database.server.id": "184054",
    "database.server.name": "dbserver1",
    "database.allowPublicKeyRetrieval": "true",
    "database.include.list": "testdb",
    "database.history.kafka.bootstrap.servers": "kafka:9092",
    "database.history.kafka.topic": "dbhistory.testdb",
    "key.converter": "org.apache.kafka.connect.json.JsonConverter",
    "key.converter.schemas.enable": "true",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter.schemas.enable": "true",
    "transforms": "unwrap,addTopicPrefix",
    "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
    "transforms.addTopicPrefix.type":"org.apache.kafka.connect.transforms.RegexRouter",
    "transforms.addTopicPrefix.regex":"(.*)",
    "transforms.addTopicPrefix.replacement":"$1"
  }
}'


connector.class는 커넥터의 Java 클래스입니다.
tasks.max는 이 커넥터에 대해 생성되어야 할 태스크의 최대 수입니다.
database.hostname은 DB 엔드포인트입니다

database.server.name는 MySQL 인스턴스를 고유하게 식별하는 데 사용할 수있는 문자열입니다.
database.include.list는 지정한 서버에서 호스팅하는 데이터베이스의 목록을 포함합니다.
database.history.kafka.bootstrap.servers는 부트스트랩 서버 주소
database.history.kafka.topic은 데이터베이스 스키마 변경을 추적하기 위해 Debezium에서 내부적으로 사용하는 Kafka 주제입니다.

==============================================
curl -i -X PUT -H  "Content-Type:application/json" \
    http://localhost:8083/connectors/source-debezium-orders-00/config \
    -d '{
            "connector.class": "io.debezium.connector.mysql.MySqlConnector",
            "value.converter": "io.confluent.connect.json.JsonSchemaConverter",
            "value.converter.schemas.enable": "true",
            "value.converter.schema.registry.url": "'$SCHEMA_REGISTRY_URL'",
            "value.converter.basic.auth.credentials.source": "'$BASIC_AUTH_CREDENTIALS_SOURCE'",
            "value.converter.basic.auth.user.info": "'$SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO'",
            "database.hostname": "mysql",
            "database.port": "3306",
            "database.user": "debezium",
            "database.password": "dbz",
            "database.server.id": "42",
            "database.server.name": "asgard",
            "table.whitelist": "demo.orders",
            "database.history.kafka.bootstrap.servers": "'$BOOTSTRAP_SERVERS'",
            "database.history.consumer.security.protocol": "SASL_SSL",
            "database.history.consumer.sasl.mechanism": "PLAIN",
            "database.history.consumer.sasl.jaas.config": "org.apache.kafka.common.security.plain.PlainLoginModule required username=\"'$CLOUD_KEY'\" password=\"'$CLOUD_SECRET'\";",
            "database.history.producer.security.protocol": "SASL_SSL",
            "database.history.producer.sasl.mechanism": "PLAIN",
            "database.history.producer.sasl.jaas.config": "org.apache.kafka.common.security.plain.PlainLoginModule required username=\"'$CLOUD_KEY'\" password=\"'$CLOUD_SECRET'\";",
            "database.history.kafka.topic": "dbhistory.demo",
            "topic.creation.default.replication.factor": "3",
            "topic.creation.default.partitions": "3",
            "decimal.handling.mode": "double",
            "include.schema.changes": "true",
            "transforms": "unwrap,addTopicPrefix",
            "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
            "transforms.addTopicPrefix.type":"org.apache.kafka.connect.transforms.RegexRouter",
            "transforms.addTopicPrefix.regex":"(.*)",
            "transforms.addTopicPrefix.replacement":"mysql-debezium-$1"
    }'


    {
    "name": "jdbc-connector",  
    "config": {
        "connector.class": "io.debezium.connector.jdbc.JdbcSinkConnector",  
        "tasks.max": "1",  
        "connection.url": "jdbc:postgresql://localhost/db",  
        "connection.username": "pguser",  
        "connection.password": "pgpassword",  
        "insert.mode": "upsert",  
        "delete.enabled": "true",  
        "primary.key.mode": "record_key",  
        "schema.evolution": "basic",  
        "use.time.zone": "UTC",  
        "topics": "orders" 
    }
}

name: Kafka Connect 서비스에 등록할 때 커넥터에 할당되는 이름입니다.
connector.class: JDBC 싱크 커넥터 클래스의 이름입니다.
tasks.max: 이 커넥터에 대해 생성할 수 있는 최대 작업 수입니다.
connection.url: 커넥터가 쓰기 작업을 수행하는 싱크 데이터베이스에 연결하는 데 사용하는 JDBC URL입니다.
insert.mode: 커넥터가 사용하는 삽입 모드입니다 .
delete.enabled: 데이터베이스에서 레코드 삭제를 활성화합니다. 자세한 내용은 delete.enabled 구성 속성을 참조하세요.
primary.key.mode: 기본 키 열을 해결하는 데 사용되는 방법을 지정합니다. 자세한 내용은 primary.key.mode 구성 속성을 참조하세요.
schema.evolution: 커넥터가 대상 데이터베이스의 스키마를 진화시킬 수 있도록 합니다. 자세한 내용은 schema.evolution 구성 속성을 참조하세요.
use.time.zone: 시간 필드 유형을 작성할 때 사용되는 시간대를 지정합니다.
topics: 쉼표로 구분된 소비 주제 목록입니다.



