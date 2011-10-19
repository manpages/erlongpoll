-module(example_example).

-compile(export_all).

-include_lib("yaws/include/yaws_api.hrl").


work(_, _) -> 
	show(hehe:run("erlongpoll/example/upload_test.hehe")).

show(Content) ->
    [   
        {header, {content_type, "text/html; charset=utf-8"}},
        {html, hehe:run("erlongpoll/example/outer.hehe", [
            {content, Content}
        ])} 
        %{html, Content}
    ].
