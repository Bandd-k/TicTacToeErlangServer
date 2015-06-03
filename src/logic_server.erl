-module(logic_server).
-behaviour(gen_server).

-export([start_link/0]).
-export([start/0]).
-export([get_all_names_and_scores/1, insert/1, insert/3,checkHalf/4,someOneWon/0]).

-export([init/1,
  handle_call/3,
  handle_cast/2,
  handle_info/2,
  terminate/2,
  code_change/3]).

-define(SERVER, ?MODULE).
-define(LINK, {global, ?SERVER}).
-define(DB_FILENAME, "data/test6.tab").
-include("student.hrl").

start_link() ->
  io:format("Starting logic server~n"),
  gen_server:start_link(?LINK, ?MODULE, [], []).

open_db_file() ->
  try
    dets:open_file(?MODULE, [
      {file, ?DB_FILENAME},
      {auto_save, 1000},
      {type, bag}
    ])
  catch
    Cls:Msg  ->
      io:format("Can't open DB file: ~s : ~s~n", [Cls, Msg]),
      {error, dberr}
  end.

init([]) -> open_db_file().


handle_call({get_items, TheresholdFunction}, _From, State) ->
  Reply = dets:foldl(
    fun(Item, Acc)->
      case TheresholdFunction(Item) of
        true -> [Item|Acc];
        false -> Acc
      end
    end, [], State),
  {reply, Reply, State}.

handle_cast({insert, Studient}, State) ->
  dets:insert(State, Studient),
  {noreply, State}.


handle_info(_Info, State) -> {noreply, State}.


terminate(_Reason, _State) -> ok.

code_change(_OldVsn, State, _Extra) -> {ok, State}.

start() -> start_link().

get_all_names_and_scores(Thereshold) when is_function(Thereshold) ->
  gen_server:call(?LINK, {get_items, Thereshold});

get_all_names_and_scores(Thereshold) when is_number(Thereshold) ->
  StandardFunction = fun(Item) ->
    Score = Item#student.ycord * 0.3 + Item#student.xcord * 0.7,
    Score >= Thereshold
  end,
  get_all_names_and_scores(StandardFunction).

insert(Studient) -> gen_server:cast(?LINK, {insert, Studient}).
insert(Name, ScoreFirst, ScoreSecond) ->
  insert(#student{login=Name, xcord =ScoreFirst, ycord=ScoreSecond}).



someOneWon()->
  List =[{"denis",1,1},{"denis",2,2},{"denis",3,3},{"denis",4,4},{"igor",5,5},{"denis",6,6}], % filled cells
  X = {1,0},
  Y = {0,1},
  Z = {1,1},
  T = {1,-1}, %% paths
  [Head|_] = List,
  {Name,_,_} = Head,
  Answer = checkFullLine(List,Head,X) or checkFullLine(List,Head,Y) or checkFullLine(List,Head,Z) or checkFullLine(List,Head,T),
  if Answer -> Name;
    true -> 0
  end.
checkHalf(List,Start,Path,N)->
  {Name,X,Y} = Start,
  {PlusX,PlusY} = Path,
  NewCell = {Name,X+PlusX,Y +PlusY},
  case lists:member(NewCell,List) of
    true -> checkHalf(List,NewCell,Path,N+1);
    _ -> N
  end.

checkFullLine(List,Start,Path)->
  {X,Y}= Path,
  (checkHalf(List,Start,Path,0)+checkHalf(List,Start,{-X,-Y},0))>=4.





