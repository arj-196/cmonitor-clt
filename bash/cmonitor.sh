#!/usr/bin/env bash
#
# Preparing arguments
label=$1
command=$2
hostname="http://localhost:3000/api"
wait_interval=1

echo "--------------------------------"
echo "---    Monitoring Command    ---"
echo "--------------------------------"
echo "-> Label      : ${label}"
echo "-> Command    : ${command}"


submit_start () {
    echo "curl POST ${hostname}/task --label=\"${label}\" --command=\"${command}\""
    # TODO retrieve task id
    task="some task id"
    echo "curl POST ${hostname}/task/instance --task=\"${task}\""
    instance="some instance id"
}

submit_end () {
    echo "curl DELETE ${hostname}/task/instance --task=\"${task}\" --instance=\"${instance}\""
}

submit_running () {
    echo "curl UPDATE ${hostname}/task/instance --task=\"${task}\" --instance=\"${instance}\""
}

#
# launch command

submit_start
echo "-> TaskId     : ${task}"
echo "-> InstanceId : ${instance}"

# actually run command
${command} &
pid=$!  # get process pid
echo "-> ProcessId  : ${pid}"


#
# wait for command to finish

process_count () {
    search_pattern="${pid}.*${command}"
    ps aux | grep "${search_pattern}" | wc -l > /tmp/cmonitor.txt
    read count < /tmp/cmonitor.txt
    pcount=${count}
}

process_count
var=0
while [ "$pcount" != "1" ]
do
    let "var=var+wait_interval"
    process_count
    echo -ne "-> Run time   : ${var} seconds\r"
    sleep ${wait_interval}
    submit_running
done

echo "-> Run time   : ${var} seconds"






#echo -ne '#####                     (33%)\r'
#sleep 1
#echo -ne '#############             (66%)\r'
#sleep 1
#echo -ne '#######################   (100%)\r'
#echo -ne '\n'

#
#ps aux | grep "${command}"


submit_end