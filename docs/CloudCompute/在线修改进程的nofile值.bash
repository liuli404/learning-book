#!/bin/bash
ERROR_SET_MAX_FILE_AVOID=1
SUCCESS=0
function log()
{
    echo "$@"
}

function log_with_pid()
{
    pid=$1
    shift 1
    if [ ! -f "/proc/$pid/cmdline" ];then
        return 0
    else
        log ERROR "$@"
        return 1
    fi
}

function modify_value()
{
    local ret=0
    param=$1
    value=$2
    modify_file=$3

    sed -i '$a\'${param}'='${value}'' ${modify_file}
    ret=$?
    if [ $ret -ne 0 ];then
        log ERROR "modify ${param} failed in ${modify_file}.ret: ${ret}"
        return 1
    fi
    cur_value="$(grep -w ${param} ${modify_file} | awk -F '=' '{printf $2}')"
    if [ "$cur_value" -ne ${value} ];then
        log ERROR "modify ${param} to ${target_value} failed in ${modify_file}."
        return 1
    fi
    log INFO "modify ${param} success in ${modify_file}."
    return 0
}

function reload_config()
{
    local ret=0
    local target_value=$1
    if [ -z "${target_value}" ];then
        systemctl daemon-reload
        ret=$?
        if [ $ret -ne 0 ];then
            log ERROR "systemctl reload failed.ret = $ret."
            systemctl daemon-reexec
            ret=$?
            if [ $ret -ne 0 ];then
                log ERROR "systemctl reexec failed.ret = $ret."
                return 1
            fi
        fi
        return 0
    fi

    cur_value=$(systemctl show | grep -w DefaultLimitNOFILE | awk -F '=' '{print $2}')
    if [ -n "${cur_value}" ] && [ "${cur_value}" -eq "${target_value}" ];then
        return 0
    fi
    systemctl daemon-reload
    ret=$?
    if [ $ret -ne 0 ];then
        log ERROR "systemctl reload failed.ret = $ret."
    fi
    cur_value=$(systemctl show | grep -w DefaultLimitNOFILE | awk -F '=' '{print $2}')
    if [ -z "${cur_value}" ] || [ "${cur_value}" -ne "${target_value}" ];then
        systemctl daemon-reexec #sytstemdÖØÆô  ÈÈÖØÆô 
        ret=$?
        if [ $ret -ne 0 ];then
            log ERROR "systemctl reexec failed.ret = $ret."
            return 1
        fi
        cur_value=$(systemctl show | grep -w DefaultLimitNOFILE | awk -F '=' '{print $2}')
        if { [ -n "${cur_value}" ] && [ "${cur_value}" -ne "${target_value}" ]; };then
            log ERROR "reload config failed. cur_value: ${cur_value}"
            return 1
        fi
    fi

    return 0
}

function set_default_limit_nofile()
{
    local ret=0
    local target_value="102400"
    local modify_file="/etc/systemd/system.conf"
    local bak_file="/tmp/system.conf"
    if [ ! -f "${modify_file}"  ];then
        log ERROR "${modify_file} is not exist."
        return 1
    fi

    if [ ! -f "${bak_file}" ];then
        cp -rf ${modify_file} ${bak_file}
        ret=$?
        if [ $ret -ne 0 ];then
            log ERROR "back up ${modify_file} failed.ret: $ret"
            return 1
        fi
        log INFO "back up ${modify_file} success."
    fi

    str="$(grep -w "[[:space:]]*DefaultLimitNOFILE[[:space:]]*=[[:space:]]*${target_value}" ${modify_file} | grep -v \# )"
    if [ -n "$str" ];then
        log INFO "DefaultLimitNOFILE value is ${target_value}, no need to modify.str: ${str}."
        return 0
    fi
    str="$(grep -w DefaultLimitNOFILE ${modify_file})"
    if [ -z "$str" ];then
        modify_value DefaultLimitNOFILE ${target_value} ${modify_file}
        if [ $? -eq 0 ];then
            reload_config ${target_value}
            return $?
        else
            return 1
        fi
    fi

    value="$(echo "$str" | awk -F '=' '{printf $2}')"
    if [ -n "$(echo "$str" | grep \#)" ] || { [ -z "$value" ] || [ "$value" -ne "${target_value}" ];};then
        sed -i "/[[:space:]]*DefaultLimitNOFILE[[:space:]]*=/d" ${modify_file}
        ret=$?
        if [ $ret -ne 0 ];then
            log ERROR "delete DefaultLimitNOFILE failed in ${modify_file}.ret: ${ret}"
            return 1
        fi
    fi
    modify_value DefaultLimitNOFILE ${target_value} ${modify_file}
    if [ $? -eq 0 ];then
        reload_config ${target_value}
        return $?
    else
        return 1
    fi
    return 0
}

function modify_max_open_file_by_pid()
{
    local ret=0
    pid=$1
    local target_value="102400"
    if [  ! -f "/proc/$pid/limits" ];then
        log INFO "$pid is not exist."
        return 0
    fi
    cur_value="$(grep -w "Max open files" /proc/$pid/limits | awk '{print $4}')"
    if [ -z "$cur_value" ];then
        log INFO "pid $pid get max open files value failed."
        return 0
    fi

    if [ "${cur_value}" -ge 65536 ];then
        return 0
    fi

    if [ "${cur_value}" -lt "${target_value}" ];then
        prlimit --pid $pid --nofile=${target_value} 2>&1
        ret=$?
        if [ $ret -ne 0 ];then
            log_with_pid $pid "modify $pid max open files value failed. cmd: prlimit --pid $pid --nofile=${target_value}. ret: ${ret}"
            return $?
        fi
        new_value=$(grep -w "Max open files" /proc/$pid/limits | awk '{print $4}')
        if [ -n "${new_value}" ] && [ "${new_value}" -ne "${target_value}" ];then
            log ERROR "modify $pid max open files value to ${target_value} failed. cur_value:${new_value}"
            return 1
        fi
        log INFO "modify $pid max open files value ${cur_value} to ${target_value} done."
        return 0
    else
        return 0
    fi
}

function modify_max_data_size_by_pid()
{
    local ret=0
    pid=$1
    key="Max data size"
    target_value="32212254720"
    if [  ! -f "/proc/$pid/limits" ];then
        log INFO "$pid is not exist."
        return 0
    fi
    cur_value="$(grep -w "${key}" /proc/$pid/limits | awk '{print $4}')"
    if [ -z "$cur_value" ];then
        log INFO "pid $pid get ${key} value failed."
        return 0
    fi
   
    if [ "${cur_value}" != "${target_value}" ];then
        prlimit --pid $pid --data=${target_value} 2>&1
        ret=$?
        if [ $ret -ne 0 ];then
            log_with_pid $pid "modify $pid ${key} value failed. cmd: prlimit --pid $pid --data=${target_value}, ret: ${ret}"
            return $?
        fi
        new_value=$(grep -w "${key}" /proc/$pid/limits | awk '{print $4}')
        if [ -n "${new_value}" ] && [ "${new_value}" -ne "${target_value}" ];then
            log ERROR "modify $pid ${key} value to ${target_value} failed. cur_value:${new_value}"
            return 1
        fi
        log INFO "modify $pid ${key} value ${cur_value} to ${target_value} done."
        return 0
    else
        return 0
    fi
}

function modify_max_stack_size_by_pid()
{
    local ret=0
    pid=$1
    key="Max stack size"
    target_value="unlimited"
    if [  ! -f "/proc/$pid/limits" ];then
        log INFO "$pid is not exist."
        return 0
    fi

    cur_value="$(grep -w "${key}" /proc/$pid/limits | awk '{print $4}')"
    if [ -z "$cur_value" ];then
        log INFO "pid $pid get ${key} value failed."
        return 0
    fi
    if [ "${cur_value}" != "${target_value}" ];then
        prlimit --pid $pid --stack=${target_value} 2>&1
        ret=$?
        if [ $ret -ne 0 ];then
            log_with_pid $pid "modify $pid ${key} value failed. cmd: c --pid $pid --stack=${target_value} ret: ${ret}"
            return $?
        fi
        new_value=$(grep -w "${key}" /proc/$pid/limits | awk '{print $4}')
        if [ -n "${new_value}" ] && [ "${new_value}" != "${target_value}" ];then
            log ERROR "modify $pid ${key} value to ${target_value} failed. cur_value:${new_value}"
            return 1
        fi
        log INFO "modify $pid ${key} value ${cur_value} to ${target_value} done."
        return 0
    else
        return 0
    fi
}

function modify_process_limits()
{
    local process_name_list=($@)
    cmd_list=$(ps -eo pid,cmd)
    err_num=0
    for process in ${process_name_list[@]}
    do
        pid_list=$(echo "$cmd_list" | grep -w $process | awk '{print $1}')
        if [ -z "$pid_list" ];then
            log INFO "can not get pid for $process."
            continue
        fi
        for pid in ${pid_list[@]}
        do
            log INFO "start to modify process_name: $process, pid: $pid"
            modify_max_open_file_by_pid $pid
            if [ $? -ne 0 ];then
                log ERROR "modify max open file for $process $pid failed."
                ((err_num++))
            fi
            modify_max_data_size_by_pid $pid
            if [ $? -ne 0 ];then
                log ERROR "modify max data size for $process $pid failed."
                ((err_num++))
            fi
            modify_max_stack_size_by_pid $pid
            if [ $? -ne 0 ];then
                log ERROR "modify max stack size for $process $pid failed."
                ((err_num++))
            fi
        done
    done
    if [ $err_num -ne 0 ];then
        log ERROR " modify max open file err num:${err_num}."
        return 1
    fi
    return 0
}

function modify_process_limits_for_mcs()
{
    local ret=0
    pid=$(ps -ef | grep health_check_register_info| grep container.conf | grep -v grep | awk -F ' ' '{print $2}')
    log INFO "start to modify process_name: health_check_register_info, pid: $pid"

    if [ -z "$pid" ];then
        return 0
    fi

    modify_max_open_file_by_pid $pid
    if [ $? -ne 0 ];then
        log ERROR "modify max open file for mcs $pid failed."
        ret=1
    fi
    modify_max_data_size_by_pid $pid
    if [ $? -ne 0 ];then
        log ERROR "modify max data size for $process $pid failed."
        ret=1
    fi
    modify_max_stack_size_by_pid $pid
    if [ $? -ne 0 ];then
        log ERROR "modify max stack size for $process $pid failed."
        ret=1
    fi
    return $ret
}

function modify_process_limits_for_network()
{
    local ret=0
    pid_list=()
    pid=$(ps -ef | grep -w neutron-bm-switch-agent | grep neutron_bm_switch.conf | grep -v heartBeat.py | grep -v grep | awk -F ' ' '{print $2}')
    pid_list=("${pid_list[@]} $pid")
    pid=$(ps -ef | grep -w neutron-server | grep neutron.conf | grep -v heartBeat.py | grep -v grep | awk -F ' ' '{print $2}')
    pid_list=("${pid_list[@]} $pid")
    pid=$(ps -ef | grep -w neutron-l3-dummy-agent | grep neutron_l3_dummy.conf | grep -v heartBeat.py | grep -v grep | awk -F ' ' '{print $2}')
    pid_list=("${pid_list[@]} $pid")
    pid=$(ps -ef | grep -w pecado-local-controller | grep local_controller.conf | grep -v heartBeat.py | grep -v grep | awk -F ' ' '{print $2}')
    pid_list=("${pid_list[@]} $pid")
    pid=$(ps -ef | grep -w neutron-dhcp-agent | grep neutron_dhcp.conf | grep -v heartBeat.py | grep -v grep | awk -F ' ' '{print $2}')
    pid_list=("${pid_list[@]} $pid")
    pid=$(ps -ef | grep -w neutron-l3-agent | grep neutron_dvr_compute.conf | grep -v heartBeat.py | grep -v grep | awk -F ' ' '{print $2}')
    pid_list=("${pid_list[@]} $pid")
    pid=$(ps -ef | grep -w neutron-metadata-agent | grep neutron_metadata.conf | grep -v heartBeat.py | grep -v grep | awk -F ' ' '{print $2}')
    pid_list=("${pid_list[@]} $pid")
    pid=$(ps -ef | grep -w neutron-openvswitch-agent | grep neutron_ovs.conf | grep -v heartBeat.py | grep -v grep | awk -F ' ' '{print $2}')
    pid_list=("${pid_list[@]} $pid")
    pid=$(ps -ef | grep -w pecado-agent | grep pecado_agent.conf | grep -v heartBeat.py | grep -v grep | awk -F ' ' '{print $2}')
    pid_list=("${pid_list[@]} $pid")

    if [ "${#pid_list[@]}" -le 0 ];then
        log INFO "get network pid list failed."
        return 0
    fi

    for pid in ${pid_list[@]}
    do
        log INFO "start to modify pid: $pid."
        modify_max_open_file_by_pid $pid
        if [ $? -ne 0 ];then
            log ERROR "modify max open file for $pid failed."
            ((err_num++))
        fi
        modify_max_data_size_by_pid $pid
        if [ $? -ne 0 ];then
            log ERROR "modify max data size for $pid failed."
            ((err_num++))
        fi
        modify_max_stack_size_by_pid $pid
        if [ $? -ne 0 ];then
            log ERROR "modify max stack size for $pid failed."
            ((err_num++))
        fi
    done
    if [ $err_num -ne 0 ];then
        log ERROR " modify max open file err num:${err_num}."
        return 1
    fi
}

function modify_tasks_limits()
{
    err_num=0
    while read pid
    do
        if [ ! -f "/proc/$pid/cmdline" ];then
            continue
        fi
        cur_cmdline=$(cat /proc/$pid/cmdline)
        if [ -n "$(echo "$cur_cmdline" | grep dsware)" ];then
            continue
        fi
        
        if [ -n "$(echo "$cur_cmdline" | grep -w "/opt/omm/oma")" ];then
            continue
        fi
        modify_max_open_file_by_pid $pid
        if [ $? -ne 0 ];then
            log ERROR "modify max open file for $pid failed. cmdline: $cur_cmdline"
            ((err_num++))
        fi
        modify_max_data_size_by_pid $pid
        if [ $? -ne 0 ];then
            log ERROR "modify max data size for $pid failed. cmdline: $cur_cmdline"
            ((err_num++))
        fi
        modify_max_stack_size_by_pid $pid
        if [ $? -ne 0 ];then
            log ERROR "modify max stack size for $pid failed. cmdline: $cur_cmdline"
            ((err_num++))
        fi
    done <<< "$(cat /sys/fs/cgroup/cpuset/system.slice/fsp/tasks /sys/fs/cgroup/cpuset/system.slice/fsp/*/tasks)"

    if [ $err_num -ne 0 ];then
        log ERROR " modify max open file err num:${err_num}."
        return 1
    fi
}

function modify_process_limits_for_quasar_server()
{
    local ret=0
    pid_list=()
    pid=$(ps -ewwf|grep -w quasar-server |grep heartBeat|awk '{print $2}')
    pid_list=("${pid_list[@]} $pid")
    pid=$(ps -ewwf|grep -v grep |grep "lib/quasar-server.*.jar"|grep -v Control|awk '{print $2}')
    pid_list=("${pid_list[@]} $pid")
    pid=$(ps -ewwf |grep -w quasar-server |grep -w quasar_certcheck |awk '{print $2}')
    pid_list=("${pid_list[@]} $pid")

    if [ "${#pid_list[@]}" -le 0 ];then
        log INFO "get quasar_server pid list failed."
        return 0
    fi

    for pid in ${pid_list[@]}
    do
        log INFO "start to modify pid: $pid."
        modify_max_open_file_by_pid $pid
        if [ $? -ne 0 ];then
            log ERROR "modify max open file for $pid failed."
            ((err_num++))
        fi
        modify_max_data_size_by_pid $pid
        if [ $? -ne 0 ];then
            log ERROR "modify max data size for $pid failed."
            ((err_num++))
        fi
        modify_max_stack_size_by_pid $pid
        if [ $? -ne 0 ];then
            log ERROR "modify max stack size for $pid failed."
            ((err_num++))
        fi
    done
    if [ $err_num -ne 0 ];then
        log ERROR " modify max open file err num:${err_num}."
        return 1
    fi
}

function check_cps_limit()
{
    local pid_name_list=("cpsclient.py" "cps_monitor.py" "upgclient.py")
    local ps_ret=$(ps aux |grep -wE "cpsclient.py|cps_monitor.py|upgclient.py" |grep -v grep)
    local ret=0
    
    for pid_name in ${pid_name_list[@]}
    do
        pid_list=$(echo "${ps_ret}" | grep -w ${pid_name} | awk '{print $2}')
        for pid in ${pid_list}
        do
            mof=$(grep "Max open files" /proc/${pid}/limits 2>/dev/null | awk '{print $4}')
            if [ -z "${mof}" ]; then
                continue
            fi
            
            if [ ${mof} -eq 65536 ] || [ ${mof} -eq 102400 ]
            then
                continue
            fi
        
            ret=1
            log ERROR "pid(${pid}), pid_name(${pid_name}), limits(${mof}) is wrong"
        done
    done
    
    if [ $ret -eq 0 ]; then
        log INFO "All cps limit is right"
    fi
    return $ret
}

function handle_modify()
{
    log INFO "start to modify systemd limits."
    set_default_limit_nofile
    if [ $? -ne 0 ];then
        log ERROR "set DefaultLimitNOFILE failed in ${modify_file}."
        ret=1
    fi

    check_cps_limit
    if [ $? -eq 0 ];then
        return 0
    fi

    log INFO "start to modify fsp tasks"
    modify_tasks_limits
    if [ $? -ne 0 ];then
        log ERROR "modify tasks limits failed."
        ret=1
    fi

    log INFO "start to modify cinder's limits."
    #cinder
    cinder_name_list=("cinder-api" "cinder-scheduler" "cinder-volume-kvm001" "cinder-volume-kvm002" "quartz-api" )
    modify_process_limits "${cinder_name_list[@]}"
    if [ $? -ne 0 ];then
        log ERROR "modify cinder process limits failed."
        ret=1
    fi

    log INFO "start to modify gaussdb ceilometer ces-collector limits."
    # gaussdb ceilometer ces-collector
    ceilometer_name_list=("gauss" "ceilometer" "ces-collector")
    modify_process_limits "${ceilometer_name_list[@]}"
    if [ $? -ne 0 ];then
        log ERROR "modify ceilometer process limits failed."
        ret=1
    fi
    
    log INFO "start to modify bms's limits."
    #bms
    bms_name_list=("ironic" "shellinabox" "tftpd")
    modify_process_limits "${bms_name_list[@]}"
    if [ $? -ne 0 ];then
        log ERROR "modify bms process limits failed."
        ret=1
    fi

    log INFO "start to modify cps limits."
    #cps
    cps_name_list=("cps-client" "cps-monitor" "upg-client")
    modify_process_limits "${cps_name_list[@]}"
    if [ $? -ne 0 ];then
        log ERROR "modify cps process limits failed."
        ret=1
    fi

    log INFO "start to modify nova limits."
    #nova
    nova_name_list=("config-file=/etc/nova/nova-api.conf" "config-file=/etc/nova/nova-conductor.conf" "config-file=/etc/nova/nova-conductor" "config-file=/etc/nova/nova-scheduler.conf" \
    "config-file=/etc/nova/nova-estimator.conf" "config-file=/etc/nova/nova-proxy" "config-file=/etc/nova/nova-console" "memcached" "config-file=/etc/nova/nova-novncproxy.conf"\
    "config-file=/etc/nova/nova-raz-mq-proxy-edge" "/etc/deh/deh-server.conf" "/etc/deh/deh-agent.conf" "config-file=/etc/nova-compute/nova-compute.conf" \
    "config-file=/etc/autorecovery/autorecovery-had" "conf=/etc/quasar-compute/quasar-compute.yaml" "config-file=/etc/quasar-compute-driver/quasar-compute-driver.conf"\
    "conf=/etc/instance-metadata/instance-metadata.conf")
    modify_process_limits "${nova_name_list[@]}"
    if [ $? -ne 0 ];then
        log ERROR "modify nova process limits failed."
        ret=1
    fi

    log INFO "start to modify glance limits."
    #glance
    glance_name_list=("/etc/glance/glance-api.conf" "/etc/glance/glance-registry.conf" "/etc/glance/glance-scrubber.conf")
    modify_process_limits "${glance_name_list[@]}"
    if [ $? -ne 0 ];then
        log ERROR "modify glance process limits failed."
        ret=1
    fi

    log INFO "start to modify mcs limits."
    #mcs
    modify_process_limits_for_mcs
    if [ $? -ne 0 ];then
        log ERROR "modify mcs process limits failed."
        ret=1
    fi

    log INFO "start to modify network limits."
    modify_process_limits_for_network
    if [ $? -ne 0 ];then
        log ERROR "modify network process limits failed."
        ret=1
    fi

    log INFO "start to modify quasar-server limits."
    modify_process_limits_for_quasar_server
    if [ $? -ne 0 ];then
        log ERROR "modify network process limits failed."
        ret=1
    fi


    if [ $ret -ne 0 ];then
        return $ERROR_SET_MAX_FILE_AVOID
    fi
    return 0
}

function handle_rollback()
{
    local bak_file="/tmp/system.conf"
    local modify_file="/etc/systemd/system.conf"
    local ret=0
    if [ ! -f "${bak_file}" ];then
        log ERROR "${bak_file} is not exist, can not rollback."
        return 1
    fi
    
    bak_str="$(grep -w DefaultLimitNOFILE ${bak_file})"
    sed -i "/[[:space:]]*DefaultLimitNOFILE[[:space:]]*=/d" ${modify_file}
    ret=$?
    if [ $ret -ne 0 ];then
        log ERROR "sed delete DefaultLimitNOFILE failed.ret = $ret."
        return 1
    fi
    if [ -n "$bak_str" ];then
        sed -i '$a\'${bak_str}'' ${modify_file}
        ret=$?
        if [ $ret -ne 0 ];then
            log ERROR "sed delete DefaultLimitNOFILE failed.ret = $ret."
            return 1
        fi
    fi
    value="$(echo "$bak_str" | awk -F '=' '{printf $2}')"
    reload_config ${value}
    return $?
}

function main()
{
    local ret=0

    if [ $# -ne 1 ];then
        log ERROR "need one para, modify or rollback."
        exit 1
    fi
    cur_version=$(grep nodeVersion /opt/dsware/DSwareAgentNodeVersion | awk -F '=' '{print $2}')
    if ! [[ "$cur_version" =~ "23.12." || "$cur_version" =~ "23.9." ]];then
        log INFO "current version is ${cur_version}, not 23.9.* and not 23.12.*, no need to modify limits."
        return $SUCCESS
    fi

    if [ ! -f "/etc/euleros-release" ];then
        log INFO "os type is not euler, no need to modify limits."
        return $SUCCESS
    fi
    if [ -n "$(cat /etc/euleros-release |grep "SP2")" ];then
        log INFO "os type is euler2.2, no need to modify limits."
        return $SUCCESS
    fi

    if [ ! -f "/usr/bin/FusionStorageAgentControl" ];then
        log INFO "node type is not compute or fusion."
        return $SUCCESS
    fi

    if [ "$1" == "modify" ];then
        handle_modify
        if [ $? -eq 0 ];then
            log INFO "modify DefaultLimitNOFILE and process limits success."
        else
            log ERROR "rollback DefaultLimitNOFILE  and process limits fail."
            return 1
        fi
    elif [ "$1" == "rollback" ];then
        handle_rollback
        if [ $? -eq 0 ];then
            log INFO "rollback DefaultLimitNOFILE success."
        else
            log ERROR "rollback DefaultLimitNOFILE fail."
            return 1
        fi
    else
        log ERROR "para error,pls input modify or rollback."
        exit 1
    fi
    return $?
}


main $@
