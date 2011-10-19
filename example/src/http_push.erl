-module(http_push).

-include_lib("yaws/include/yaws_api.hrl").

-compile(export_all).

-export([
	work/2,
	loop/2
]).

work ([PollID], _) ->
	case (get_session_id()) of
		{value, SessionID} -> 
			Descriptor = {poll, PollID, session, SessionID},

			% Have a look at descriptorbox.erl and redefine functions there if you
			% want to use another way to store PIDs for longpoll descriptors.
			descriptors:del(Descriptor),

			PID = spawn(?MODULE, loop, [self(), Descriptor]),
			descriptors:set(Descriptor, PID),
			io:format ("LONG_POLL: poll_id and forked PID: ~p ~p~n", [PollID, PID]),
			initialize_stream("[ ");

		_ -> 
			io:format ("LONG_POLL: <<FATAL>> failed to get session ID~n"),
			false
	end
.

loop (WorkPID, Descriptor) ->
	receive
	stop ->
		descriptors:del(Descriptor),
		io:format ("LONG_POLL: <<STOP>> stop received~n"),
		deliver_chunk(WorkPID, "true, true ]"),
		terminate_stream(WorkPID);
	{data, Data} ->
		descriptors:del(Descriptor),
		io:format ("LONG_POLL: data received - `~p`~n", [Data]),
		deliver_chunk(WorkPID, "false, " ++ Data ++ " ]"),

		% We terminate stream each time to make handling of push notifications
		% easier (see Poll() in longpoll.js). The connection is reestablished
		% if the first JSON element is FALSE. If the first element is TRUE then
		% clientside won't poll anymore.
		terminate_stream(WorkPID);
	X -> %debug only
		io:format ("LONG_POLL <<WARNING>>: something strange received ~p~n", [X]),
		loop(WorkPID, Descriptor)
	after 5000 ->
		io:format ("LONG_POLL @ ~p: testing connection for wpid `~p` on desc `~p` ~n", [self(), WorkPID, Descriptor]),
		case deliver_chunk(WorkPID, "\n", blocking) of
			ok -> 
				loop (WorkPID, Descriptor);
			{error, _} -> 
				descriptors:del(Descriptor),
				io:format("LONG_POLL: <<FATAL>> poll ~p died. client disconnected? ~n", [Descriptor])
		end
	end
.

%%%
%  
% You must redefine get_session_id functions if you want use a custom
% session id (i.e. your serverside implementation doesn't store value 
% for `uid` atom in its process dictionary or you want to extract it
% from a cookie).
%
%%%

get_session_id () ->
	case (get(uid)) of
		undefined -> false;
		0		  -> false;
		X		  -> {value, X}
	end
.

%%%
%  
% If you use YAWS HTTP server functions below will work just fine.
% Else, you have to redefine those to work with your server.
% Notice that we include yaws_api.hrl, remove it if you won't use
% YAWS.
%
%%%

initialize_stream (Data) ->
	{streamcontent, "text/html", Data}
.

deliver_chunk (WorkPID, Data) -> %returns `ok` or `{error, X}`
	yaws_api:stream_chunk_deliver(WorkPID, Data)
.

deliver_chunk (WorkPID, Data, blocking) -> %returns `ok` or `{error, X}`
	yaws_api:stream_chunk_deliver_blocking(WorkPID, Data)
.

terminate_stream (WorkPID) ->
	yaws_api:stream_chunk_end(WorkPID)
.
