%%%-------------------------------------------------------------------
%% @doc syslogd top level supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(dnsd_sup).
-behaviour(supervisor).

%% API
-export([start_link/0,start_link/1]).

%% Supervisor callbacks
-export([init/1]).


-include("common.hrl").
-define(SERVER, ?MODULE).

%%====================================================================
%% API functions
%%====================================================================

start_link() ->
    supervisor:start_link({global, ?SERVER}, ?MODULE, []).

start_link(N) ->
    supervisor:start_link({global, list_to_atom("dnsd_"++integer_to_list(N))}, ?MODULE, []).

%%====================================================================
%% Supervisor callbacks
%%====================================================================

%% Child :: {Id,StartFunc,Restart,Shutdown,Type,Modules}
init([]) ->

    Listener = { dnsd,{dnsd, start_link, []},permanent, 5000, worker, [dnsd]},

% name dnsd must be global

%    Queue_1 = { dns_queue_1,{dns_queue, start_link, [1]},permanent, 5000, worker, [dns_queue_1]},
%    Queue_2 = { dns_queue_2,{dns_queue, start_link, [2]},permanent, 5000, worker, [dns_queue_2]},

%    logger:critical(#{point => ?POINT, queues => [Queue_1,Queue_2]}),     

    {ok, { {one_for_all, 10, 10}, [Listener 
                                   %,Queue_1,Queue_2
                                  ]
         } 
    }.

%%====================================================================
%% Internal functions
%%====================================================================
