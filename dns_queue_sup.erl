%%%-------------------------------------------------------------------
%% @doc syslogd top level supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(dns_queue_sup).
-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).


-include("common.hrl").
-define(SERVER, ?MODULE).

%%====================================================================
%% API functions
%%====================================================================

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%%====================================================================
%% Supervisor callbacks
%%====================================================================

%% Child :: {Id,StartFunc,Restart,Shutdown,Type,Modules}
init([]) ->

    Queue_1 = { dns_queue_1,{dns_queue, start_remote_link, ['workers_1@de.de',1]},permanent, 5000, worker, [dns_queue_1]},
    Queue_2 = { dns_queue_2,{dns_queue, start_remote_link, ['workers_2@de.de',2]},permanent, 5000, worker, [dns_queue_2]},

    logger:critical(#{point => ?POINT, queues => [Queue_1,Queue_2]}),     

    {ok, { {one_for_all, 10, 10}, [Queue_1,Queue_2
                                  ]
         } 
    }.

%%====================================================================
%% Internal functions
%%====================================================================
