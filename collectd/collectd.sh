#!/usr/bin/env bash

cp /etc/collectd/collectd.conf /home/collectd.conf

echo "Hostname \"${HOSTNAME}\"" >> /home/collectd.conf

# Number of threads to start for reading plugins. The default value is 5,
# but you may want to increase this if you have more than five plugins that take a long time to read.
# Mostly those are plugins that do network-IO.
# Setting this to a value higher than the number of registered read callbacks is not recommended.
# Starts from 3 for the csv, cpu and memory write threads
read_plugins_counter=3

if ls /sys/class/thermal/thermal_zone* 1> /dev/null 2>&1; then
echo \
"LoadPlugin thermal

<Plugin \"thermal\">
    ForceUseProcfs false
    IgnoreSelected false
</Plugin>
" >> /home/collectd.conf
read_plugins_counter=$((read_plugins_counter+1))
fi

echo "ReadThreads $read_plugins_counter" >> /home/collectd.conf


# Add riemann write plugin
echo \
"<Plugin write_riemann>
       <Node \"igz\">
               Host ${RIEMANN_SERVER_IP}
               Port ${RIEMANN_SERVER_PORT}
               Protocol TCP
               Batch false
               StoreRates true
               AlwaysAppendDS true
               Notifications false
               CheckThresholds false
               EventServicePrefix \"${EVENT_SERVICE_PREFIX}\"
       </Node>
       Tag \"${NODE_NAME:-some_node}\"
</Plugin>
"  >> /home/collectd.conf

# Starts collectd
/opt/collectd/sbin/collectd -f -C /home/collectd.conf
