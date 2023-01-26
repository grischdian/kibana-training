for i in $(cat hostliste); do echo $i; ssh tux@$i sudo systemctl stop logstash; done
for i in $(cat hostliste); do echo $i; ssh tux@$i sudo systemctl stop metricbeat; done
for i in $(cat hostliste); do echo $i; ssh tux@$i sudo systemctl stop filebeat; done
for i in $(cat hostliste); do echo $i; ssh tux@$i sudo systemctl stop kibana; done
for i in $(cat hostliste); do echo $i; ssh tux@$i sudo systemctl stop elasticsearch; done
for i in $(cat hostliste); do echo $i; ssh tux@$i sudo yum remove elasticsearch kibana logstash metricbeat filebeat -y; done
for i in $(cat hostliste); do echo $i; ssh tux@$i sudo rm -rf /etc/logstash /etc/kibana /etc/metricbeat /etc/filebeat /etc/elasticsearch /var/lib/elasticsearch ; done
