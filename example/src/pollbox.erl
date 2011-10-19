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

sender (Descriptor, Message) -> sender (Descriptor, Message, 0).
sender (Descriptor, Message, Tries) ->
	receive
		stop -> ok
	after 1 ->
		case descriptors:val(Descriptor) of
			{value, PID} -> 
				io:format ("POLLBOX: sending ~p to ~p (~p)~n", [Message, Descriptor, PID]),
				PID ! Message,
				poll_manager ! {done, self()};
			false -> 
				case (Tries < 2500) of 
				%io:format ("POLLBOX: can't find loop for ~p~n", [Descriptor]), %too much even for debug :)
					true -> sender (Descriptor, Message, Tries+1);
					false -> false
				end
		end
	end.
