-module(dns_queue).

-include_lib("eunit/include/eunit.hrl").

-behaviour(gen_server).

-define(SERVER, ?MODULE).

%%%
%%
%%%

-export([start_link/0, start/0, start_link/1, start/1, start_remote_link/2, do/2
	]).

-export([init/1,
	 handle_call/3,
	 handle_cast/2,
	 handle_info/2,
	 terminate/2,
	 code_change/3]).

-include("common.hrl").

-export([info/0,info/1]).

%%====================================================================
%% API
%%====================================================================
start()-> 
    {ok,Pid} = start_link(),
    Pid.

start(N)-> 
    {ok,Pid} = start_link(N),
    Pid.
    
start_link() ->
    logger:?TRACE_POINTS_LEVEL(#{point => ?POINT ,subject => "start_link/0" }),   
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

start_link(N) ->
    %logger:?TRACE_POINTS_LEVEL(#{point => ?POINT ,subject => "start_link" , n => N}),   
    gen_server:start_link({global, list_to_atom(atom_to_list(?MODULE)++"_"++integer_to_list(N))}, ?MODULE, [], []).

% start queue in remote node
start_remote_link(Node,N) ->
    logger:?TRACE_POINTS_LEVEL(#{point => ?POINT ,subject => "start_link/1" , n => N}),   
    rpc:call(Node,?MODULE,start_link,[N]).
         
%%====================================================================
%% Gen Server
%%====================================================================

init(Arg) ->
    %logger:?TRACE_POINTS_LEVEL(#{point => ?POINT ,subject => "init" , state => Arg}),
    %register(?MODULE,self()),   
    {ok, #{pid => self() }}.

handle_call(Ask, _From, State) ->
    logger:?TRACE_POINTS_LEVEL(#{point => ?POINT ,subject => "handle_call" , ask => Ask, state => State }),   
    {reply, {ok, {?MODULE,?LINE,'Result'}}, State};

handle_call(What, _From, State) ->
    {reply, {error, What}, State}.

handle_cast(_What, State) ->
    {noreply, State}.

handle_info({Pid,info}, State) ->
    logger:?TRACE_POINTS_LEVEL(#{point => ?POINT ,subject => "handle_info {Pid,info} ask" , ask => info, state => State }),
    Pid!#{process_info => erlang:process_info(self()) },  
    {noreply, State};

handle_info({Pid,{info,Subject}}, State) ->
    logger:?TRACE_POINTS_LEVEL(#{point => ?POINT ,subject => "handle_info {Pid,info} ask" , ask => info, state => State }),
    Pid!erlang:process_info(self(),Subject),  
    {noreply, State};

handle_info(Ask, State) ->
    logger:?TRACE_POINTS_LEVEL(#{point => ?POINT ,subject => "handle_info" , ask => Ask, state => State }),
    case do(Ask,State) of
     R->R
     %catch Err:Reason -> ?CATCH_HANDLER({?MODULE,{catch_error,{do,#{ask => Ask, state => State}}}})
    end,   
    {noreply, State}.

terminate(Reason, State) ->
    logger:critical(#{point => ?POINT ,subject => "terminate" , ask => Reason, state => State }),   
    ok.

code_change(OldVsn, State, Extra) ->
    logger:critical(#{point => ?POINT ,subject => "code_change" , ask => OldVsn, state => State , extra => Extra}),   
    {ok, State}.

%%====================================================================
%% Internal functions
%%====================================================================

% get reply from worker
do({worker_reply,{IP,Port,Reply}},State)->
  logger:critical(#{reply => Reply, point => ?POINT, client => {IP,Port}, reply => inet_dns:decode(Reply), subject => "get message from worker"});

% get ask from listener
do({udp,Sock,ClientAddr,Port,Msg},State)->
  logger:critical(#{ msg => Msg, state => State , point => ?POINT , subject => "get message from listener"}),
  Parse=dns_workers:parse_ask(Msg),
  logger:critical(#{ parsed_ask => Parse, state => State , point => ?POINT}),
  
  % ret random worker from pool
  %   worker -> dns_workers
  W = dns_ns:pid(dns_workers,rand:uniform(?WORKERS_NUM)),
  logger:critical(#{worker_pid => W, point => ?POINT}),
  %W = dns_ns:pid(worker,1+rand:uniform(erlang:system_time() rem ?WORKERS)),
  % W = choose_worker(Addr,Workers, fun(Add,Workers_) -> random_worker(Workers_) end),
  % send ask to worker's Pid
  R=W!{self(),{Sock,ClientAddr,Port,Msg}},
  logger:?TRACE_POINTS_LEVEL(#{ask => Msg, point => ?POINT_ARG(do) , subject => "passing message to worker was done" , result => R}),
  R;


% pass Reply to listener
do({Worker_Pid,{worker_reply,Reply}},State)->
  %here will need to fetch dnsd_{N} from arguments
%  R=global:whereis_name(dnsd)!{worker_reply,Reply},                             
  R=dns_ns:pid(dnsd)!{worker_reply,Reply},                             
  logger:critical(#{reply => Reply, point => ?POINT , subject => "turn result back to listener for pass to client", result => R});
                              
do(Result,State)->
  % turn result back to client
  logger:critical(#{result => Result, point => ?POINT , subject => "unexpected message in do"}).
  
info()-> lists:map(fun(A)-> {A,info(A)} end, [dns_queue_1,dns_queue_2]).

info(Queue)->
% global:whereis_name(Queue)!{self(),info},
   R=dns_ns:pid(Queue)!{self(),info},
 receive
  R->R
  after 5000 -> {timeout,Queue,info}
 end.

info(Queue,Subject)->
% global:whereis_name(Queue)!{self(),{info,Subject}},
 dns_ns:pid(Queue)!{self(),{info,Subject}},
 receive
  {Subject,Value} -> Value;
   R->R
  after 5000 -> {timeout,Queue,info}
 end.

%%====================================================================
%% Tests
%%====================================================================

%test() ->
%    ?assert(test(0) =:= 0),
%    ?assert(test(1) =:= 1),
%    ?assert(test(2) =:= 1).
