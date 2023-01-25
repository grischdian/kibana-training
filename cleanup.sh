for i in $(cat hostliste); do echo $i; ssh tux@$i sudo yum remove elasticsearch kibana logstash metricbeat filebeat -y; done
for i in $(cat hostliste); do echo $i; ssh tux@$i sudo rm -rf /etc/logstash /etc/kibana /etc/metricbeat /etc/filebeat /etc/elasticsearch /var/lib/elasticsearch ; done
