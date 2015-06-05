-module(studients).
-export([scores/3,add/3,isWin/2]).
-import(mod_esi, [deliver/2]).
-include("student.hrl").

studient_to_json(Entry) ->
  lists:flatten(io_lib:format("{\"login\": \"~s\", \"x\": ~p, \"y\": ~p}", [
    Entry#student.login,
    Entry#student.xcord,
    Entry#student.ycord
  ])).

list_to_json(Data) ->
  "[" ++ string:join(lists:map(fun(X)->studient_to_json(X)end, Data), ", ") ++ "]".

argument_to_float(Arg) ->
  Status = string:to_float(Arg),
  DotPos = string:str(Arg, "."),
  case Status of
    {error, no_float} when length(Arg)==0 -> 0.0;
    {error, no_float} when DotPos==0 -> argument_to_float(Arg ++ ".0");
    {error, _} -> 0.0;
    {Value, []} -> Value
  end.

scores(SessionId, _Env, In) ->
  Thereshold = argument_to_float(In),
  Data = logic_server:get_all_names_and_scores(Thereshold),
  DataJSON = list_to_json(Data),
  Header = "Content-Type: application/json\r\n\r\n",
  deliver(SessionId, [Header, DataJSON]).

add(SessionId, _Env,In) ->
  [X,Y,Z] = string:tokens(In,","),
  {Xcord,_} = string:to_integer(Y),
  {Ycord,_} = string:to_integer(Z),
  if (Xcord >= 0) and (Ycord >= 0)->
  Data = logic_server:get_all_names_and_scores(0),
  logic_server:insert(X,Xcord,Ycord),
  deliver(SessionId,integer_to_list(length(logic_server:get_all_names_and_scores(0))-length(Data)));
   true -> deliver(SessionId,0)
  end.


isWin(SessionId, _Env) ->
  deliver(SessionId,logic_server:someOneWon()).


