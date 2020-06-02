-define(?PROCESS_INFO, 
handle_info({Pid,info}, State) ->
    logger:?TRACE_POINTS_LEVEL(#{point => ?POINT ,reason => "handle_info {Pid,info} ask" , ask => info, state => State }),
    Pid!#{process_info => erlang:process_info(self()) },  
    {noreply, State};

handle_info({Pid,{info,Subject}}, State) ->
    logger:?TRACE_POINTS_LEVEL(#{point => ?POINT ,reason => "handle_info {Pid,info} ask" , ask => info, state => State }),
    Pid!erlang:process_info(self(),Subject),  
    {noreply, State};
      ).