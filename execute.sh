source ~/init_opencl.sh
timing_list="";
#list="$(find ../../sandbox/aocl_i32 -executable -type f)"
list="$(find altera_gen -executable -type f)"
#list="$(find ../../sandbox/aocl_i32/max_throughput_32 -executable -type f)"
while read -r app; do
    host_name=$(echo ${app##*/})
    host_path=$(echo ${app%/*})
    aocx_count=`ls -1 ${host_path}/*.aocx 2>/dev/null | wc -l`
    if [ $aocx_count != 0 ]
    then
        cd ${host_path}
        #./${host_name} 2>&1 | tee run_app.log
        stdbuf -o0 ./${host_name} 2>&1 | tee run_app.log
        median=$(cat run_app.log | grep Timing | awk '{print $2}')
        cd -
    fi
done <<< "$list"
