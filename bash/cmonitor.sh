#!/usr/bin/env bash
#
# Preparing arguments
label=$1
command=$2
hostname="http://arj-fut.com:3000/api"
wait_interval=1

echo "--------------------------------"
echo "---    Monitoring Command    ---"
echo "--------------------------------"
echo "-> Label      : ${label}"
echo "-> Command    : ${command}"

# read -r -p "Continue? [y/N] " response
# case "$response" in
#    [yY][eE][sS]|[yY])
#        break
#        ;;
#    *)
#        echo "--- Exiting ---"
#        exit 1
#        ;;
# esac

submit_start () {
    task=$(curl -s -d "label=${label}&command=${command}" -X POST "${hostname}/task" \
                | python -c "import sys, json; print (json.loads(sys.stdin.read())['id'])")
    # for kill any active instances
    curl -s -d "task=${task}" -X POST "${hostname}/task/instance/kill"
    instance=$(curl -s -d "task=${task}" -X POST "${hostname}/task/instance" \
                | python -c "import sys, json; print (json.loads(sys.stdin.read())['id'])")
}

submit_end () {
    curl -s -d "task=${task}&instance=${instance}" -X DELETE "${hostname}/task/instance"
}

#submit_running () {
#    echo "curl -d \"task=${task}&instance=${instance}\" -X UPDATE ${hostname}/task/instance"
#}

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
    # TODO integrate logic of gathering run data, like logs
#    submit_running
done

submit_end
echo "-> Run time   : ${var} seconds"