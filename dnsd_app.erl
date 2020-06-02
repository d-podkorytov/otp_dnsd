%%%-------------------------------------------------------------------
%% @doc example public API
%% @end
%%%-------------------------------------------------------------------
-module(dnsd_app).
-include("common.hrl").

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%%====================================================================
%% API
%%====================================================================

start(_StartType, _StartArgs) -> R=dnsd_sup:start_link(),
                                   dns_queue_sup:start_link(),
                                 % in future move dns_sup and dns_queue_sup to supervision tree dnsd_add_sup and do:  
                                 %R=dnsd_app_sup:start_link(),
                                   global:sync(),
                                   logger:critical(#{point => ?POINT, global_names => dns_ns:names()}),
                                   timer:sleep(1000),
                                   dnser:test(),
                                   
                                 R.

%%--------------------------------------------------------------------
stop(_State) -> 
 ok.

%%====================================================================
%% Internal functions
%%====================================================================
