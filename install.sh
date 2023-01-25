#!/bin/bash
VM_PER_TN=3
# TN = TN + Trainer
TN=11
mkdir -p training
egrep -i '\<elastic.\>' /etc/hosts > hosts
echo "127.0.0.1 localhost" >> hosts
for i in $(seq 0 $(expr $TN - 1)); do
	echo Starting User $i
	for b in $(seq 1 $VM_PER_TN); do
        cp remote.sh ./training/$b-$i.sh
        sed -i 's/VM/'"$b"'/g' ./training/$b-$i.sh
        sed -i 's/TN/'"$i"'/g' ./training/$b-$i.sh
        echo Starting elastic-$b-$i
        NODE=elastic$b-$i
        scp hosts tux@$NODE:/tmp/hosts
        ssh tux@$NODE sudo mv /tmp/hosts /etc/hosts
        scp ./training/$b-$i.sh tux@$NODE:/tmp/remote.sh
        scp ./certs/elastic-ca.p12 tux@$NODE:/tmp/elastic-ca.p12
        scp ./certs/elastic-cert.p12 tux@$NODE:/tmp/elastic-cert.p12
        scp ./certs/http.p12 tux@$NODE:/tmp/http.p12
        scp ./certs/kibana.key tux@$NODE:/tmp/kibana.key
        scp ./certs/kibana.crt tux@$NODE:/tmp/kibana.crt
	scp ./certs/elasticsearch-ca.pem tux@$NODE:/tmp/elasticsearch-ca.pem
        ssh tux@$NODE sudo bash /tmp/remote.sh
        if [[ $b -eq 1 ]]
        then
            scp access.log tux@$NODE:/tmp/access.log
            ssh tux@$NODE sudo systemctl restart logstash
	    sleep 10
            ssh tux@$NODE sudo metricbeat setup --dashboards
        fi
        echo Finished elastic-$b-$i
	done
	echo Finished User $i
	echo "=================="
done
rm hosts

