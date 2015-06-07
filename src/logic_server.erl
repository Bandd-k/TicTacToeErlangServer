-module(logic_server).
-behaviour(gen_server).

-export([start_link/0]).
-export([start/0]).
-export([get_all_names_and_scores/1, insert/1, insert/3,checkHalf/4,someOneWon/0,get_players/0,join/1,ready/0,leave/1,next/1,restartGame/0]).

-export([init/1,
  handle_call/3,
  handle_cast/2,
  handle_info/2,
  terminate/2,
  code_change/3]).

-define(SERVER, ?MODULE).
-define(LINK, {global, ?SERVER}).
-define(DB_FILENAME, "data/test9k.tab").
-include("cell.hrl").
-record(condtition,{players = [],db}).
start_link() ->
  io:format("Starting logic server~n"),
  gen_server:start_link(?LINK, ?MODULE, [], []).

open_db_file() ->
  try
    [],dets:open_file(?MODULE, [
      {file, ?DB_FILENAME},
      {auto_save, 1000},
      {type, bag}
    ])
  catch
    Cls:Msg  ->
      io:format("Can't open DB file: ~s : ~s~n", [Cls, Msg]),
      {error, dberr}
  end.

init([]) ->
  {_,X} = open_db_file(),
  {ok,#condtition{players =[], db = X}}.



handle_call({get_items, TheresholdFunction}, _From, State) ->
  Reply = dets:foldl(
    fun(Item, Acc)->
      case TheresholdFunction(Item) of
        true -> [Item|Acc];
        false -> Acc
      end
    end, [], State#condtition.db),
  {reply, Reply, State};

handle_call({get_players},_From,State)->
  {reply,State#condtition.players,State};

handle_call({join,Name},_From,State)->
  X = State#condtition.players ++ [Name],
  NewState = #condtition{players = X,db =State#condtition.db},
  {reply,1,NewState};

handle_call({leave,Name},_From,State)->
  X = lists:delete(Name,State#condtition.players),
  {reply,1,#condtition{players = X,db = State#condtition.db}};

handle_call({restart},_From,State)->
  dets:delete_all_objects(State#condtition.db),
  {reply,1,State}.

get_players()->
  gen_server:call(?LINK,{get_players}).

join(Name)->
  X = length(get_players()),
  if X <2 ->
  gen_server:call(?LINK,{join,Name});
    true-> 0
  end.


handle_cast({insert, Studient}, State) ->
  dets:insert(State#condtition.db, Studient),
  {noreply, State}.


handle_info(_Info, State) -> {noreply, State}.




terminate(_Reason, _State) -> ok.

code_change(_OldVsn, State, _Extra) -> {ok, State}.

start() -> start_link().

get_all_names_and_scores(Thereshold) when is_function(Thereshold) ->
  gen_server:call(?LINK, {get_items, Thereshold});

get_all_names_and_scores(Thereshold) when is_number(Thereshold) ->
  StandardFunction = fun(Item) ->
    Score = Item#cell.ycord * 0.3 + Item#cell.xcord * 0.7,
    Score >= Thereshold
  end,
  get_all_names_and_scores(StandardFunction).

insert(Studient) -> gen_server:cast(?LINK, {insert, Studient}).
insert(Name, ScoreFirst, ScoreSecond) ->
  insert(#cell{login=Name, xcord =ScoreFirst, ycord=ScoreSecond}).

ready()->
  X = length(get_players()),
  if X ==2 ->
    1;
    true ->0
  end.

returnList()->
  A = get_all_names_and_scores(0),
  [{T,K,Z}  ||{student,T,K,Z} <- A].

leave(Name)->
  gen_server:call(?LINK,{leave,Name}).

next(Name)->
  Len = length(returnList()),
  if Len == 0 ->
    1;
    true -> next2(Name)
end.

next2(Name) ->
  [Head| _] = returnList(),
  {X,_,_} = Head,
  if X == Name -> 0;
    true -> 1
  end.

restartGame()->
  gen_server:call(?LINK,{restart}).



someOneWon()->
  %%List =[{"denis",1,1},{"denis",2,2},{"denis",3,3},{"denis",4,4},{"igor",5,5},{"denis",6,6}], % filled cells
  List = returnList(),
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






