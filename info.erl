-module(info).
-compile(export_all).

%sys:statistics/2/3

statistics(A,B)->sys:statistics(A,B).

erts_alloc_config()-> #{ erts_alloc_config => erts_alloc_config:state()}.

os_mon_sysinfo()->
      os_mon_sysinfo:start_link(),
    #{get_disk_info => try os_mon_sysinfo:get_disk_info() of 
                        R->R 
                    catch Err:Reason -> {Err,Reason} 
                    end,
     get_mem_info  => try os_mon_sysinfo:get_mem_info()  of R->R catch Err:Reason -> {Err,Reason} end
    }.

os()->
 #{type => os:type(),
   version => os:version()
  }.

applications()->
 #{applications => application:info()}.

init_info()->
    #{    
     get_arguments => init:get_arguments(),
     get_plain_arguments => init:get_plain_arguments(),
     script_id           => init:script_id(),
     get_status          => init:get_status()
    }.

erlang()->
    #{
    %{erlang:dist_get_stat,1},
     universaltime => erlang:universaltime(),
     time          => erlang:time()
    %{erlang:statistics(self())}
    }.

all()->#{erlang => erlang(),
         init   => init_info(),
         applications => applications(),
         erts_alloc_config => erts_alloc_config(),
         os_mon_sysinfo => os_mon_sysinfo() 
       }.    

system_information_to_file()->
 system_information:to_file(atom_to_list(node())++"-"++pid_to_list(self())++".information.txt").

%diameter_stats.beam",
%   diameter_stats,
%   [{reg,2},
%    {flush,1},
%    {start_link,0},
%    {state,0},ct.beam",ct,

%   [{install,1},
%    {run,3},
%    {run,2},
%    {run,1},
%    {run_test,1},
%    {run_testspec,1},
%    {step,3},
%    {step,4},
%    {start_interactive,0},
%    {stop_interactive,0},
%    {get_config,3},
%    {reload_config,1},
%    {get_testspec_terms,0},
%    {get_testspec_terms,1},
%    {escape_chars,1},
%    {escape_chars,2},
%    {log,1},
%    {log,2},
%    {log,3},
%    {log,4},
%    {log,5},
%    {print,1},
%    {print,2},
%    {print,3},
%    {print,4},
%    {print,5},
%    {pal,1},
%    {pal,2},
%    {pal,3},
%    {pal,4},
%    {pal,5},
%    {set_verbosity,2},
%    {get_verbosity,1},
%    {capture_start,0},
%    {capture_stop,0},
%    {capture_get,0},
%    {capture_get,1},
%    {fail,1},
%    {fail,2},
%    {comment,2},
%    {make_priv_dir,0},
%    {get_target_name,1},
%    {get_progname,0},
%    {parse_table,1},
%    {listenv,1},
%    {testcases,2},
%    {userdata,2},
%    {userdata,3},
%    {get_status,0},

diameter()->diameter:services(). %get_status().
