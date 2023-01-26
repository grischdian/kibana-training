set -x
sudo setenforce 0
sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
cat <<EOF > /tmp/elastic.repo
[elasticsearch]
name=Elasticsearch repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=0
autorefresh=1
type=rpm-md
EOF
sudo mv /tmp/elastic.repo /etc/yum.repos.d
sudo yum repolist
sudo yum install --enablerepo=elasticsearch elasticsearch kibana metricbeat filebeat logstash -y
cat <<FOO > /tmp/filebeat.yml
filebeat.inputs:
- type: filestream
  id: my-filestream-id
  enabled: false
  paths:
    - /var/log/*.log
filebeat.config.modules:
  path: /etc/filebeat/modules.d/*.yml
  reload.enabled: false
setup.template.settings:
  index.number_of_shards: 3
setup.dashboards.enabled: true
setup.kibana:
  host: "localhost:5601"
  ssl.enabled: true
  protocol: "https"
  ssl.verification_mode: none
output.elasticsearch:
  hosts: ["localhost:9200"]
  protocol: "https"
  ssl:
    certificate_authorities: ["/etc/filebeat/elasticsearch-ca.pem"]
processors:
  - add_host_metadata:
      when.not.contains.tags: forwarded
  - add_cloud_metadata: ~
  - add_docker_metadata: ~
  - add_kubernetes_metadata: ~
FOO
sudo mv /tmp/filebeat.yml /etc/filebeat/filebeat.yml

cat <<BAR > /tmp/filebeat.module.txt
- module: elasticsearch
  server:
    enabled: true
  gc:
    enabled: true
  audit:
    enabled: true
  slowlog:
    enabled: true
  deprecation:
    enabled: true
- module: system
  syslog:
    enabled: true
  auth:
    enabled: true
- module: kibana
  log:
    enabled: true
  audit:
    enabled: true
BAR
sudo mv /tmp/filebeat.module.txt /etc/filebeat/modules.d/b1-custom.yml
sudo cp /tmp/elasticsearch-ca.pem /etc/filebeat/elasticsearch-ca.pem
cat <<FOOBAR > /tmp/metricbeat.yml
metricbeat.config.modules:
  path: /etc/metricbeat/modules.d/*.yml
  reload.enabled: false
setup.template.settings:
  index.number_of_shards: 3
  index.codec: best_compression
setup.kibana:
  host: "localhost:5601"
  ssl.enabled: true
  protocol: "https"
  ssl.verification_mode: none
output.elasticsearch:
  hosts: ["localhost:9200"]
  protocol: "https"
  ssl:
    certificate_authorities: ["/etc/metricbeat/elasticsearch-ca.pem"]
processors:
  - add_host_metadata: ~
  - add_cloud_metadata: ~
  - add_docker_metadata: ~
  - add_kubernetes_metadata: ~
FOOBAR
sudo mv /tmp/metricbeat.yml /etc/metricbeat/metricbeat.yml
cat <<BARFOO > /tmp/metricbeat.module.txt
- module: elasticsearch
  metricsets:
    - node
    - node_stats
  period: 10s
  hosts: ["https://localhost:9200"]
  ssl.verification_mode: "none"
  xpack.enabled: true
- module: logstash
  xpack.enabled: true
  metricsets:
    - node
    - node_stats
  period: 10s
  hosts: ["localhost:9600"]
- module: kibana
  metricsets:
    - status
  period: 10s
  hosts: ["https://localhost:5601"]
  ssl.verification_mode: "none"
  xpack.enabled: true
- module: system
  period: 10s
  metricsets:
    - cpu
    - load
    - memory
    - network
    - process
    - process_summary
    - socket_summary
    - entropy
    - core
    - diskio
    - socket
    - service
    - users
  prcess.include_top_n:
    by_cpu: 5      # include top 5 processes by CPU
    by_memory: 5   # include top 5 processes by memory
- module: system
  period: 1m
  metricsets:
    - filesystem
    - fsstat
  processors:
  - drop_event.when.regexp:
      system.filesystem.mount_point: '^/(sys|cgroup|proc|dev|etc|host|lib|snap)($|/)'
- module: system
  period: 15m
  metricsets:
    - uptime
BARFOO
sudo mv /tmp/metricbeat.module.txt /etc/metricbeat/modules.d/b1-custom.yml
sudo cp /tmp/elasticsearch-ca.pem /etc/metricbeat/elasticsearch-ca.pem
sudo rm -f /etc/metricbeat/modules.d/system.yml
cat << KIB > /tmp/kibana.yml
server.port: 5601
server.host: 0.0.0.0
server.ssl.enabled: true
server.ssl.certificate: /etc/kibana/kibana.crt
server.ssl.key: /etc/kibana/kibana.key
elasticsearch.hosts: ["https://localhost:9200"]
elasticsearch.ssl.certificateAuthorities: /etc/kibana/elasticsearch-ca.pem
KIB
sudo mv /tmp/kibana.yml /etc/kibana/kibana.yml
sudo cp /tmp/elasticsearch-ca.pem /etc/kibana/elasticsearch-ca.pem
sudo mv /tmp/kibana.crt /etc/kibana/kibana.crt
sudo mv /tmp/kibana.key /etc/kibana/kibana.key
cat << ELASTIC > /tmp/elasticsearch.yml
node.name: node-VM-TN
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
#bootstrap.memory_lock: true
network.host: 0.0.0.0
discovery.seed_hosts: ["elastic1-TN"]
cluster.initial_master_nodes: ["node-1-TN"]
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.client_authentication: required
xpack.security.transport.ssl.keystore.path: elastic-ca.p12
xpack.security.transport.ssl.truststore.path: elastic-cert.p12
xpack.security.http.ssl.enabled: true
xpack.security.http.ssl.keystore.path: "http.p12"
ELASTIC
sudo mv /tmp/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml
sudo mv /tmp/elastic-ca.p12 /etc/elasticsearch/elastic-ca.p12
sudo mv /tmp/elastic-cert.p12 /etc/elasticsearch/elastic-cert.p12
sudo mv /tmp/http.p12 /etc/elasticsearch/http.p12
sudo chown elasticsearch:elasticsearch /etc/elasticsearch/elastic-ca.p12
sudo chown elasticsearch:elasticsearch /etc/elasticsearch/elastic-cert.p12
sudo chown elasticsearch:elasticsearch /etc/elasticsearch/http.p12
sudo chmod 600 /etc/elasticsearch/elastic-ca.p12
sudo chmod 600 /etc/elasticsearch/elastic-cert.p12
sudo chmod 600 /etc/elasticsearch/http.p12
cat << FILTER > /tmp/filter.conf
input {
  file {
    path => ["/tmp/access_1.log"]
    start_position => "beginning"
    sincedb_path => "/dev/null"
  }
  file {
    path => ["/tmp/access_2.log"]
    start_position => "beginning"
    sincedb_path => "/dev/null"
  }
  file {
    path => ["/tmp/access_3.log"]
    start_position => "beginning"
    sincedb_path => "/dev/null"
  }
}

filter {
  grok {
    match => { "message" => "%{COMBINEDAPACHELOG}" }
  }
  date {
    match => ["timestamp", "dd/MMM/yyyy:HH:mm:ss Z"] 
  }
}

output {
  elasticsearch {
  hosts => ["https://localhost:9200"]
  ssl_certificate_verification => false
  ssl => true
  }
}
FILTER
sudo mv /tmp/filter.conf /etc/logstash/conf.d
cat << LOG > /tmp/logstash.yml
path.data: /var/lib/logstash
config.reload.automatic: true
config.reload.interval: 3s
path.logs: /var/log/logstash
LOG
sudo mv /tmp/logstash.yml /etc/logstash/logstash.yml
sudo cp /tmp/elasticsearch-ca.pem /etc/logstash/elasticsearch-ca.pem
sudo systemctl restart elasticsearch
sudo systemctl restart kibana 
sleep 10 
sudo systemctl start metricbeat 
sleep 10
sudo systemctl start filebeat
