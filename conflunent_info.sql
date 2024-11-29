Confluent 란?
실시간 데이터 파이프라인 및 스티리밍 애플리케이션을 구축하는 데 사용되는 분산 이벤트 스트리밍 플랫폼.
실시간 분석, 데이터 수집, 이벤트 기반 아키텍쳐와 같은 사례에 적합


[용어 정리]
- 클러스터 외부
Connect : Connector를 동작하게 하는 프로세서 (서버)
Connector : Data를 어디에서(source) 어디로(sink) 복사할지 관리, 데이터를 처리하는 코드가 담긴 jar 패키지 
 ㄴ converter 설정을 통해 커넥터와 브로커 사이에 주고 받는 메시지를 어떻게 변환하여 저장할 것인지 설정 
Source Connector : Data Source의 데이터를 카프카 토픽에 보내는 역할을 하는 커넥터 (Producer)
Sink Connector : 카프카 토픽에 담긴 데이터를 특정 Data Source로 보내는 역할을 하는 커넥터 (Consumer)
Schema Registry : Data의 스키마 등록 및 조회, 버전관리, 호환성 체크등의 기능을 제공 
Ksql DB : 실시간 스트리밍 데이터를 처리, 내부 토픽을 Sub하여 분석하거나 Sub한 토픽을 정제하여 다시 토픽으로 Pub 가능  
Transforms : 메시지를 간단하게 수정할 수 있게 하는 tool (다만 다소 복잡한 변환을 수행해야 할 경우에는 KsqlDB나 Kafka Streams 사용을 권함.)
하나의 데이터를 받아 데이터를 수정해서 내보낸다.
여러개의 Transforms을 연결(chain)해서 하나의 connector에서 설정이 가능 

- 클러스터 내부
Broker : 각 kafka 클러스터의 노드(서버, 부트스트랩 서버),  n개의 topic으로 구성된다
부트스트랩 서버 : kafka client (producer, consumer 등)이 브로커와 연결하여 브로커 내부의 자원에 접근할 때 원하는 자원의 위치 (어떤 브로커에 해당 토픽이 저장되어 있는지)를 알기위한 메타데이터 공유.
Topic : kafka의 가장 기본적인 조직단위, 이벤트 스트림 구성 및 저장
새로운 이벤트 메시지가 topic에 기록되면 해당 메시지가 로그 끝에 추가된다.
이벤트가 기록된 후에는 변경 불가능
consumer가 각 topic을 읽으며 offset을 기록하여 순차적으로 log를 읽는다.
해당 topic을 구독하는 consumer는 0~n 개가 될 수 있다.
이벤트를 전송한 후에도 일정 기간동안 삭제되지 않는다.

# Connector를 생성
curl -X POST http://localhost:8083/connectors -H "Content-Type: application/json" -d [JSON타입의 설정]
curl -X POST http://localhost:8083/connectors -H "Content-Type: application/json" -d@경로

==============================================================================================
curl --location --request POST 'http://localhost:8083/connectors' \
--header 'Content-Type: application/json' \
--data-raw '{
  "name": "sink-test-connector",
  "config": {
    "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
    "tasks.max": "1",
    "connection.url": "jdbc:mysql://mysql-sink:3306/sinkdb?user=mysqluser&password=mysqlpw",
    "auto.create": "false",
    "auto.evolve": "false",
    "delete.enabled": "true",
    "insert.mode": "upsert",
    "pk.mode": "record_key",
    "table.name.format":"${topic}",
    "tombstones.on.delete": "true",
    "connection.user": "mysqluser",
    "connection.password": "mysqlpw",
    "topics.regex": "dbserver1.testdb.(.*)",
    "key.converter": "org.apache.kafka.connect.json.JsonConverter",
    "key.converter.schemas.enable": "true",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter.schemas.enable": "true",
    "transforms": "unwrap, route, TimestampConverter",
    "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
    "transforms.unwrap.drop.tombstones": "true",
    "transforms.route.type": "org.apache.kafka.connect.transforms.RegexRouter",
    "transforms.route.regex": "([^.]+)\\.([^.]+)\\.([^.]+)",
    "transforms.route.replacement": "$3",
    "transforms.TimestampConverter.type": "org.apache.kafka.connect.transforms.TimestampConverter$Value",
    "transforms.TimestampConverter.format": "yyyy-MM-dd HH:mm:ss",
    "transforms.TimestampConverter.target.type": "Timestamp",
    "transforms.TimestampConverter.field": "update_date"
  }
}'


auto.create: 자동 테이블 생성 (절대 하면 안됨)
auto.evolve : 자동 컬럼 생성
delete.enabled: null record를 삭제로 처리, pk.mode가 record_key 여야 한다.
insert.mode : upsert, insert, update
topics.regex : topics 대신 정규식으로 topic 받아올 수 있음

======================================
# 주제 접두사 제거
"transforms": "dropPrefix",
"transforms.dropPrefix.type": "org.apache.kafka.connect.transforms.RegexRouter",
"transforms.dropPrefix.regex": "soe-(.*)",
"transforms.dropPrefix.replacement": "$1"

전에:soe-Order
후에:Order

======================================
# 주제 접두사 추가
"transforms": "AddPrefix",
"transforms.AddPrefix.type": "org.apache.kafka.connect.transforms.RegexRouter",
"transforms.AddPrefix.regex": ".*",
"transforms.AddPrefix.replacement": "acme_$0"

전에:Order
후에:acme_Order

======================================
# 주제 이름의 일부를 제거
"transforms=RemoveString",
"transforms.RemoveString.type": "org.apache.kafka.connect.transforms.RegexRouter",
"transforms.RemoveString.regex": "(.*)Stream_(.*)",
"transforms.RemoveString.replacement": "$1$2"

전에:Order_Stream_Data
후에:Order_Data


- regex	        일치에 사용할 정규 표현식
- replacement	교체용 문자열

"transforms": "route",
"transforms.route.type": "org.apache.kafka.connect.transforms.RegexRouter",
"transforms.route.regex": "([^.]+)\\.([^.]+)\\.([^.]+)",
"transforms.route.replacement": "$3"


# TimestampConverter
아래와 같은 이슈가 발생하여 TimestampConverter 를 추가 

"transforms": "TimestampConverter",
"transforms.TimestampConverter.type": "org.apache.kafka.connect.transforms.TimestampConverter$Value",
"transforms.TimestampConverter.format": "yyyy-MM-dd HH:mm:ss",
"transforms.TimestampConverter.target.type": "Timestamp",
"transforms.TimestampConverter.field": "update_date"

=================================================================================

curl -X POST http://localhost:8083/connectors -H "Content-Type: application/json" -d '{
     "name": "jdbc_source_mysql_01",
     "config": {
             "connector.class": "io.confluent.connect.jdbc.JdbcSourceConnector",
             "connection.url": "jdbc:mysql://mysql:3306/test",
             "connection.user": "connect_user",
             "connection.password": "connect_password",
             "topic.prefix": "mysql-01-",
             "poll.interval.ms" : 3600000,
             "table.whitelist" : "test.accounts",
             "mode":"bulk",
             "transforms":"createKey,extractInt",
             "transforms.createKey.type":"org.apache.kafka.connect.transforms.ValueToKey",
             "transforms.createKey.fields":"id",
             "transforms.extractInt.type":"org.apache.kafka.connect.transforms.ExtractField$Key",
             "transforms.extractInt.field":"id",
             "catalog.pattern" : "demo"
             }
     }'

{"name" : "test_connector",
    "config" : {
        "connector.class": "io.confluent.connect.jdbc.JdbcSourceConnector",
        "connection.url": "jdbc:postgresql://12.34.5.6:5432/",
        "connection.user": "user",
        "connection.password": "password",
        "key.converter": "org.apache.kafka.connect.storage.StringConverter",
        "topic.prefix": "incre_",
        "mode": "incrementing",
        "value.converter": "io.confluent.connect.avro.AvroConverter",
        "query" :"SELECT cast(replace(id, 'ab','') as integer) as id , name from test ORDER BY id ASC",
        "incrementing.column.name":"id",
        "value.converter.schema.registry.url": "http://schema-registry_url.com",
        "key.converter.schema.registry.url": "http://schema-registry_url.com",
        "offset.flush.timeout.ms": 2000
    }
}

속성의 의미는 다음과 같습니다.
name : source connector 이름(JdbcSourceConnector를 사용)
config.connector.class : 커넥터 종류(JdbcSourceConnector 사용)
config.connection.url : jdbc이므로 DB의 connection url 정보 입력
config.connection.user : DB 유저 정보
config.connection.password : DB 패스워드
config.mode : "테이블에 데이터가 추가됐을 때 데이터를 polling 하는 방식"(bulk, incrementing, timestamp, timestamp+incrementing)
config.incrementing.column.name : incrementing mode일 때 자동 증가 column 이름
poll.interval.ms: 소스 테이블을 복제하는 polling하고 복제하는 간격
catalog.pattern : kafka 토픽에 저장될 이름 pattern 지정

[mode 설명]
bulk : 데이터를 폴링할 때 마다 전체 테이블을 복사
incrementing : 특정 컬럼의 중가분만 감지되며, 기존 행의 수정과 삭제는 감지되지 않음
incrementing.column.name : incrementing 모드에서 새 행을 감지하는 데 사용할 컬럼명
timestamp : timestamp형 컬럼일 경우, 새 행과 수정된 행을 감지함
timestamp.column.name : timestamp 모드에서 COALESCE SQL 함수를 사용하여 새 행 또는 수정된 행을 감지
timestamp+incrementing : 위의 두 컬럼을 모두 사용하는 옵션


=============================================================================================
- connector.class <= Connector를 생성하기 위해서 필요한 클래스를 작성한다. 
connector.class : "io.confluent.connect.jdbc.JdbcSourceConnector"

- connection.url <= 데이터베이스 접근을 위한 주소를 설정한다.
connection.url : "jdbc:mysql://localhost:3306/mydatabase"

- Connection.user, Connection.password <= 데이터베이스 접속을 위한 ID와 Password를 설정한다.
connection.user : "root"
connection.password : "root"

- Topic.prefix
Topic 생성시 이름앞에 붙일 접두어. 여기서 작성한 prefix와 테이블명이 Topic의 이름이 된다. ( prefix + 테이블명 ) 
(토픽 생성에 대해선 뒤에 있는 옵션에서 설명.)
Topic.prefix : "jdbc-connector-"

- MODE
테이블에 변경이 발생했을때 어떤 방식으로 데이터를 poll할지 셋팅한다. 
bulk를 사용하면 이벤트가 발생한 테이블의 내용을 모두 poll한다.
incrementing은 incrementing column을 통해서 신규로 들어온 row를 판단하고, 해당 데이터만 poll해온다. 
여기서 주의해야할점은 incrementing모드의 경우에 "삭제(delete)"와 "수정(update)"에 대해선 작동하지 않는다는 점이다. 
따라서 수정과 삭제정보도 poll하고 싶다면 shadow테이블을 만들어야 할것이다. 

mode : "incrementing"

- incrementing.column.name
incrementing column을 셋팅한다. id라는 컬럼명을 보고 어떤 row부터 poll할지 판단한다. 
설정한 column의 타입이 varchar인 경우 에러가 난다.

incrementing.column.name : "id"

- poll.interval.ms
테이블에서 새로운 데이터에 대해 데이터를 폴링하는 주기를 설정한다.

poll.interval.ms : 10000

- table.whitelist
데이터를 poll할 테이블의 목록을 셋팅한다. 복수개의 테이블에서 데이터를 가져오는경우 콤마(,)를 통해서 작성한다.

table.whitelist: "user"

- topic.creation.default.replication.factor 
Source Connector를 실행했을때 Topic이 존재하지 않는다면 Source Connector는 자동으로 Topic을 생성할 수있다. 
이때 몇가지 조건이 존재하는데 먼저 worker의 설정파일에서 topic.creation.enable=true 로 셋팅해야한다. 
( 사실 default값이 true이므로 따로 설정하지 않아도 된다. ) 
이렇게 하면 자동으로 default라는 이름으로 topic create group이 생성되는데 이 그룹은 topic 생성을 담당한다. 
아래 작성한 옵션은 default 그룹으로 topic을 자동생성할때 replication factor옵션을 1로 셋팅하겠다는 뜻이다. 
Topic 자동생성을 위해서 반드시 셋팅되어야한다. 

topic.creation.default.replication.factor : 1

- topic.creation.default.partitions
위와 마찬가지로 Topic 자동 생성을 위해 반드시 셋팅되어야 하는 값이다. 
default 그룹을 통해 topic을 자동생성할때 파티션을 몇개로 셋팅할지 정하는 옵션이다. 
추가로 설명하면 사용자가 default이외의 그룹을 만들수 있으며 
그룹마다 이런 replication factor나 partition옵션을 셋팅할 수 있다. 
그리고 include, exclude 옵션을 통해서 사용자가 생성한 그룹으로 topic을 생성할지 제외할지 선택할 수 있다. 
현재는 필요없는 설정이므로 따로 그룹을 만들진 않았다.

topic.creation.default.partitions : 1
=============================================================================================================

{
    "name": "source_tb_iv_member",
    "config": {
        "connector.class" : "io.confluent.connect.jdbc.JdbcSourceConnector",
        "connection.url" : "jdbc:mysql://localhost:3306/kafka_test",
        "connection.user" : "root",
        "connection.password" : "qwer1234",
        "topic.prefix" : "topic_",
        "poll.interval.ms" : 2000,
        "table.whitelist" : "tb_iv_member",
        "mode" : "incrementing",
        "incrementing.column.name":"mem_uno",
        "topic.creation.default.replication.factor" : 1,
        "topic.creation.default.partitions" : 1
    }
}

{
    "name": "source_tb_iv_member_join",
    "config": {
        "connector.class" : "io.confluent.connect.jdbc.JdbcSourceConnector",
        "connection.url" : "jdbc:mysql://localhost:3306/kafka_test",
        "connection.user" : "root",
        "connection.password" : "qwer1234",
        "topic.prefix" : "topic_",
        "poll.interval.ms" : 2000,
        "table.whitelist" : "tb_iv_member_join",
        "mode" : "timestamp+incrementing",
        "incrementing.column.name":"mem_uno",
        "timestamp.column.name":"mem_join_date",
        "topic.creation.default.replication.factor" : 1,
        "topic.creation.default.partitions" : 1
        "validate.non.null":"false"
    }
}

insert 시 mem_join_date에 not null 조건이 없어서 에러 발생 시
validate.non.null 옵션을 false로 설정하여 null 검사를 비활성화하면 topic에 데이터가 정상적으로 생성

{
    "name": "source_tb_iv_member_detail",
    "config": {
        "connector.class" : "io.confluent.connect.jdbc.JdbcSourceConnector",
        "connection.url" : "jdbc:mysql://localhost:3306/kafka_test",
        "connection.user" : "root",
        "connection.password" : "qwer1234",
        "topic.prefix" : "topic_",
        "poll.interval.ms" : 10000,
        "table.whitelist" : "tb_iv_member_detail",
        "mode" : "bulk",
        "query": "",
        "validate.non.null": "false",
        "topic.creation.default.replication.factor" : 1,
        "topic.creation.default.partitions" : 1
    }
}

Sink Connector 생성
{
    "name": "sink_tb_iv_member_detail",
    "config": {
        "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
        "connection.url": "jdbc:mysql://localhost:3306/kafka_test",
        "connection.user":"root",
        "connection.password":"qwer1234",
        "tasks.max": "1",
        "auto.create": "false",
        "auto.evolve": "false",
        "topics": "topic_tb_iv_member_detail",
        "insert.mode": "upsert",
        "table.name.format":"kafka_test.tb_iv_member_detail_sink",
        "key.converter": "org.apache.kafka.connect.json.JsonConverter",
        "key.converter.schemas.enable": "true",
        "value.converter": "org.apache.kafka.connect.json.JsonConverter",
        "value.converter.schemas.enable": "true"
    }
}

[상태 확인하기]
curl -X GET http://localhost:8083/connectors/jdbc_source_altibase_01/status
{"name":"jdbc_source_altibase_01","connector":{"state":"RUNNING","worker_id":"127.0.1.1:8083"}

[삭제하기]
curl -X DELETE http://localhost:8083/connectors/jdbc_source_altibase_01ㅎ