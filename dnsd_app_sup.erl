%%%-------------------------------------------------------------------
%% @doc dnsd top level supervisors tree .
%% @end
%%%-------------------------------------------------------------------

-module(dnsd_app_sup).
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

    Listener_sup = { dnsd_sup,{dnsd_sup, start_link, []},permanent, 5000, supervisor, [dnsd_sup]},

    Queue_sup = { dns_queue_sup,{dns_queue_sup, start_link, []},permanent, 5000, supervisor, [dns_queue_sup]},
    %Queue_2 = { dns_queue_2,{dns_queue, start_link, [2]},permanent, 5000, worker, [dns_queue_2]},

    logger:critical(#{point => ?POINT, subject => start, supervisors => [Listener_sup,Queue_sup]}),     

    {ok, { {one_for_all, 10, 10}, [Listener_sup,Queue_sup
                                  ]
         } 
    }.

%%====================================================================
%% Internal functions
%%====================================================================
