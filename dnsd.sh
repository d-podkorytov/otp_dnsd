#!/bin/sh
echo start $0
erl -name dnsd@de.de -s dnsd | tee $0.log
#-kernel_logger '[{handler,default,logger_disk_log_h,#{config => #{file => "./dnsd_.log"}}}]' 
