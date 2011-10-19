-module(pollbox).

-compile(export_all).

start() ->
	case whereis(poll_manager) of 
		undefined -> ok;
		_ -> unregister(poll_manager)
	end,
	PID = spawn(?MODULE, receiver, [[]]),
	erlang:register(poll_manager, PID),
	{ok, PID}.

stop() ->
	poll_manager ! stop.

receiver(Senders) ->
	receive
		{done, PID} ->
			receiver(lists:delete(PID, Senders));
		{Descriptor, stop} ->
			lists:foreach(fun(X) -> X ! stop end, Senders),
			PID = spawn(?MODULE, sender, [Descriptor, stop]),
			receiver([]);
		{Descriptor, Message} ->
			PID = spawn(?MODULE, sender, [Descriptor, Message]),
			receiver([PID|Senders]);
		stop ->
			ok
	end.

sender (Descriptor, Message) ->
	receive
		stop -> ok
	after 0 ->
		case fission_syn:get(Descriptor) of
			{value, PID} -> 
				io:format ("POLLBOX: sending ~p to ~p (~p)~n", [Message, Descriptor, PID]),
				PID ! Message,
				poll_manager ! {done, self()};
			false -> 
				%io:format ("POLLBOX: can't find loop for ~p~n", [Descriptor]), %too much even for debug :)
				sender (Descriptor, Message)
		end
	end.
