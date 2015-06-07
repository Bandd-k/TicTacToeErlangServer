-module(game).
-export([cells/3,add/3,isWin/3,ready/3,join/3,leave/3,next/3,restart/3]).
-import(mod_esi, [deliver/2]).
-include("cell.hrl").

studient_to_json(Entry) ->
  lists:flatten(io_lib:format("{\"login\": \"~s\", \"x\": ~p, \"y\": ~p}", [
    Entry#cell.login,
    Entry#cell.xcord,
    Entry#cell.ycord
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

cells(SessionId, _Env, In) ->
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


isWin(SessionId, _Env,_) ->
  deliver(SessionId,integer_to_list(logic_server:someOneWon())).

join(SessionId, _Env,In) ->
  deliver(SessionId,integer_to_list(logic_server:join(In))).

leave(SessionId,_Env,In) ->
  deliver(SessionId,integer_to_list(logic_server:leave(In))).

ready(SessionId,_Env,_) ->
  deliver(SessionId,integer_to_list(logic_server:ready())).

next(SessionId,_Env,In)->
  deliver(SessionId,integer_to_list(logic_server:next(In))).

restart(SessionId,_Env,_)->
  deliver(SessionId,integer_to_list(logic_server:restartGame())).

