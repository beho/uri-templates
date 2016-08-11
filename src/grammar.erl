-module(grammar).
-export([parse/1,file/1]).
-define(p_charclass,true).
-define(p_choose,true).
-define(p_label,true).
-define(p_one_or_more,true).
-define(p_optional,true).
-define(p_scan,true).
-define(p_seq,true).
-define(p_string,true).
-define(p_zero_or_more,true).



-spec file(file:name()) -> any().
file(Filename) -> case file:read_file(Filename) of {ok,Bin} -> parse(Bin); Err -> Err end.

-spec parse(binary() | list()) -> any().
parse(List) when is_list(List) -> parse(unicode:characters_to_binary(List));
parse(Input) when is_binary(Input) ->
  _ = setup_memo(),
  Result = case 'uri_template'(Input,{{line,1},{column,1}}) of
             {AST, <<>>, _Index} -> AST;
             Any -> Any
           end,
  release_memo(), Result.

-spec 'uri_template'(input(), index()) -> parse_result().
'uri_template'(Input, Index) ->
  p(Input, Index, 'uri_template', fun(I,D) -> (p_zero_or_more(p_choose([fun 'literals'/2, fun 'expression'/2])))(I,D) end, fun(Node, Idx) ->transform('uri_template', Node, Idx) end).

-spec 'literals'(input(), index()) -> parse_result().
'literals'(Input, Index) ->
  p(Input, Index, 'literals', fun(I,D) -> (p_choose([p_charclass(<<"[\\x21\\x23-\\x24\\x26\\x28-\\x3B\\x3D\\x3F-\\x5B\\x5D\\x5F\\x61-\\x7A\\x7E]">>), fun 'ucschar'/2, fun 'iprivate'/2, fun 'pct_encoded'/2]))(I,D) end, fun(Node, Idx) ->transform('literals', Node, Idx) end).

-spec 'expression'(input(), index()) -> parse_result().
'expression'(Input, Index) ->
  p(Input, Index, 'expression', fun(I,D) -> (p_seq([p_string(<<"{">>), p_label('op', p_optional(fun 'operator'/2)), p_label('vars', fun 'variable_list'/2), p_string(<<"}">>)]))(I,D) end, fun(Node, _Idx) ->
  [_, {op, OpBin}, {vars, Vars}, _ | []] = Node,
  Op = case OpBin of
    [] -> none;
    OpBin -> OpBin
  end,
  {expression, Op, Vars}
 end).

-spec 'operator'(input(), index()) -> parse_result().
'operator'(Input, Index) ->
  p(Input, Index, 'operator', fun(I,D) -> (p_choose([fun 'op_level_2'/2, fun 'op_level_3'/2, fun 'op_reserve'/2]))(I,D) end, fun(Node, Idx) ->transform('operator', Node, Idx) end).

-spec 'op_level_2'(input(), index()) -> parse_result().
'op_level_2'(Input, Index) ->
  p(Input, Index, 'op_level_2', fun(I,D) -> (p_charclass(<<"[\\+#]">>))(I,D) end, fun(Node, Idx) ->transform('op_level_2', Node, Idx) end).

-spec 'op_level_3'(input(), index()) -> parse_result().
'op_level_3'(Input, Index) ->
  p(Input, Index, 'op_level_3', fun(I,D) -> (p_charclass(<<"[\\.\/;\\?&]">>))(I,D) end, fun(Node, Idx) ->transform('op_level_3', Node, Idx) end).

-spec 'op_reserve'(input(), index()) -> parse_result().
'op_reserve'(Input, Index) ->
  p(Input, Index, 'op_reserve', fun(I,D) -> (p_charclass(<<"[=,!@|]">>))(I,D) end, fun(Node, Idx) ->transform('op_reserve', Node, Idx) end).

-spec 'variable_list'(input(), index()) -> parse_result().
'variable_list'(Input, Index) ->
  p(Input, Index, 'variable_list', fun(I,D) -> (p_seq([p_label('first', fun 'varspec'/2), p_label('rest', p_zero_or_more(p_seq([p_string(<<",">>), fun 'varspec'/2])))]))(I,D) end, fun(Node, _Idx) ->
  [{first, First}, {rest, Rest} | []] = Node,
  [First | lists:map( fun([_,V|[]]) -> V end, Rest)]
 end).

-spec 'varspec'(input(), index()) -> parse_result().
'varspec'(Input, Index) ->
  p(Input, Index, 'varspec', fun(I,D) -> (p_seq([p_label('v', fun 'varname'/2), p_label('m', p_optional(fun 'modifier_level_4'/2))]))(I,D) end, fun(Node, _Idx) ->
  [{v, V}, {m, M}|[]] = Node,
  {varspec, V, M}
 end).

-spec 'varname'(input(), index()) -> parse_result().
'varname'(Input, Index) ->
  p(Input, Index, 'varname', fun(I,D) -> (p_seq([p_label('first', fun 'varchar'/2), p_label('rest', p_zero_or_more(p_seq([p_optional(p_string(<<".">>)), fun 'varchar'/2])))]))(I,D) end, fun(Node, _Idx) ->
  % transform to list of binary chars while filtering optional dots
  [{first,First}, {rest, Rest} | []] = Node,
  [First|lists:filter(fun(E) -> size(E) > 0 end, lists:flatten(Rest))]
 end).

-spec 'varchar'(input(), index()) -> parse_result().
'varchar'(Input, Index) ->
  p(Input, Index, 'varchar', fun(I,D) -> (p_choose([fun 'ALPHA'/2, fun 'DIGIT'/2, p_string(<<"_">>), fun 'pct_encoded'/2]))(I,D) end, fun(Node, Idx) ->transform('varchar', Node, Idx) end).

-spec 'modifier_level_4'(input(), index()) -> parse_result().
'modifier_level_4'(Input, Index) ->
  p(Input, Index, 'modifier_level_4', fun(I,D) -> (p_choose([fun 'prefix'/2, fun 'explode'/2]))(I,D) end, fun(Node, Idx) ->transform('modifier_level_4', Node, Idx) end).

-spec 'prefix'(input(), index()) -> parse_result().
'prefix'(Input, Index) ->
  p(Input, Index, 'prefix', fun(I,D) -> (p_seq([p_string(<<":">>), fun 'max_length'/2]))(I,D) end, fun(Node, _Idx) ->
[_, L | []] = Node,
{prefix, L}
 end).

-spec 'max_length'(input(), index()) -> parse_result().
'max_length'(Input, Index) ->
  p(Input, Index, 'max_length', fun(I,D) -> (p_one_or_more(fun 'DIGIT'/2))(I,D) end, fun(Node, _Idx) ->
lists:foldl(fun(<<N:8>>, A) -> A*10 + (N - $0) end, 0, Node)
 end).

-spec 'explode'(input(), index()) -> parse_result().
'explode'(Input, Index) ->
  p(Input, Index, 'explode', fun(I,D) -> (p_string(<<"*">>))(I,D) end, fun(_Node, _Idx) ->
{explode}
 end).

-spec 'ucschar'(input(), index()) -> parse_result().
'ucschar'(Input, Index) ->
  p(Input, Index, 'ucschar', fun(I,D) -> (p_choose([p_charclass(<<"[\\xA0-\\x{D7FF}]">>), p_charclass(<<"[\\x{F900}-\\x{FDCF}]">>), p_charclass(<<"[\\x{FDF0}-\\x{FFEF}]">>), p_charclass(<<"[\\x{10000}-\\x{1FFFD}]">>), p_charclass(<<"[\\x{20000}-\\x{2FFFD}]">>), p_charclass(<<"[\\x{30000}-\\x{3FFFD}]">>), p_charclass(<<"[\\x{40000}-\\x{4FFFD}]">>), p_charclass(<<"[\\x{50000}-\\x{5FFFD}]">>), p_charclass(<<"[\\x{60000}-\\x{6FFFD}]">>), p_charclass(<<"[\\x{70000}-\\x{7FFFD}]">>), p_charclass(<<"[\\x{80000}-\\x{8FFFD}]">>), p_charclass(<<"[\\x{90000}-\\x{9FFFD}]">>), p_charclass(<<"[\\x{A0000}-\\x{AFFFD}]">>), p_charclass(<<"[\\x{B0000}-\\x{BFFFD}]">>), p_charclass(<<"[\\x{C0000}-\\x{CFFFD}]">>), p_charclass(<<"[\\x{D0000}-\\x{DFFFD}]">>), p_charclass(<<"[\\x{E1000}-\\x{EFFFD}]">>)]))(I,D) end, fun(Node, Idx) ->transform('ucschar', Node, Idx) end).

-spec 'iprivate'(input(), index()) -> parse_result().
'iprivate'(Input, Index) ->
  p(Input, Index, 'iprivate', fun(I,D) -> (p_charclass(<<"[\\x{E000}-\\x{F8FF}\\x{F0000}-\\x{FFFFD}\\x{100000}-\\x{10FFFD}]">>))(I,D) end, fun(Node, Idx) ->transform('iprivate', Node, Idx) end).

-spec 'pct_encoded'(input(), index()) -> parse_result().
'pct_encoded'(Input, Index) ->
  p(Input, Index, 'pct_encoded', fun(I,D) -> (p_seq([p_string(<<"%">>), fun 'HEXDIG'/2, fun 'HEXDIG'/2]))(I,D) end, fun(Node, _Idx) ->
[_, A, B | []] = Node,
{pct, A, B}
 end).

-spec 'ALPHA'(input(), index()) -> parse_result().
'ALPHA'(Input, Index) ->
  p(Input, Index, 'ALPHA', fun(I,D) -> (p_charclass(<<"[a-zA-Z]">>))(I,D) end, fun(Node, Idx) ->transform('ALPHA', Node, Idx) end).

-spec 'DIGIT'(input(), index()) -> parse_result().
'DIGIT'(Input, Index) ->
  p(Input, Index, 'DIGIT', fun(I,D) -> (p_charclass(<<"[0-9]">>))(I,D) end, fun(Node, Idx) ->transform('DIGIT', Node, Idx) end).

-spec 'HEXDIG'(input(), index()) -> parse_result().
'HEXDIG'(Input, Index) ->
  p(Input, Index, 'HEXDIG', fun(I,D) -> (p_charclass(<<"[0-9a-fA-F]">>))(I,D) end, fun(Node, Idx) ->transform('HEXDIG', Node, Idx) end).


transform(_,Node,_Index) -> Node.
-file("peg_includes.hrl", 1).
-type index() :: {{line, pos_integer()}, {column, pos_integer()}}.
-type input() :: binary().
-type parse_failure() :: {fail, term()}.
-type parse_success() :: {term(), input(), index()}.
-type parse_result() :: parse_failure() | parse_success().
-type parse_fun() :: fun((input(), index()) -> parse_result()).
-type xform_fun() :: fun((input(), index()) -> term()).

-spec p(input(), index(), atom(), parse_fun(), xform_fun()) -> parse_result().
p(Inp, StartIndex, Name, ParseFun, TransformFun) ->
  case get_memo(StartIndex, Name) of      % See if the current reduction is memoized
    {ok, Memo} -> %Memo;                     % If it is, return the stored result
      Memo;
    _ ->                                        % If not, attempt to parse
      Result = case ParseFun(Inp, StartIndex) of
        {fail,_} = Failure ->                       % If it fails, memoize the failure
          Failure;
        {Match, InpRem, NewIndex} ->               % If it passes, transform and memoize the result.
          Transformed = TransformFun(Match, StartIndex),
          {Transformed, InpRem, NewIndex}
      end,
      memoize(StartIndex, Name, Result),
      Result
  end.

-spec setup_memo() -> ets:tid().
setup_memo() ->
  put({parse_memo_table, ?MODULE}, ets:new(?MODULE, [set])).

-spec release_memo() -> true.
release_memo() ->
  ets:delete(memo_table_name()).

-spec memoize(index(), atom(), parse_result()) -> true.
memoize(Index, Name, Result) ->
  Memo = case ets:lookup(memo_table_name(), Index) of
              [] -> [];
              [{Index, Plist}] -> Plist
         end,
  ets:insert(memo_table_name(), {Index, [{Name, Result}|Memo]}).

-spec get_memo(index(), atom()) -> {ok, term()} | {error, not_found}.
get_memo(Index, Name) ->
  case ets:lookup(memo_table_name(), Index) of
    [] -> {error, not_found};
    [{Index, Plist}] ->
      case proplists:lookup(Name, Plist) of
        {Name, Result}  -> {ok, Result};
        _  -> {error, not_found}
      end
    end.

-spec memo_table_name() -> ets:tid().
memo_table_name() ->
    get({parse_memo_table, ?MODULE}).

-ifdef(p_eof).
-spec p_eof() -> parse_fun().
p_eof() ->
  fun(<<>>, Index) -> {eof, [], Index};
     (_, Index) -> {fail, {expected, eof, Index}} end.
-endif.

-ifdef(p_optional).
-spec p_optional(parse_fun()) -> parse_fun().
p_optional(P) ->
  fun(Input, Index) ->
      case P(Input, Index) of
        {fail,_} -> {[], Input, Index};
        {_, _, _} = Success -> Success
      end
  end.
-endif.

-ifdef(p_not).
-spec p_not(parse_fun()) -> parse_fun().
p_not(P) ->
  fun(Input, Index)->
      case P(Input,Index) of
        {fail,_} ->
          {[], Input, Index};
        {Result, _, _} -> {fail, {expected, {no_match, Result},Index}}
      end
  end.
-endif.

-ifdef(p_assert).
-spec p_assert(parse_fun()) -> parse_fun().
p_assert(P) ->
  fun(Input,Index) ->
      case P(Input,Index) of
        {fail,_} = Failure-> Failure;
        _ -> {[], Input, Index}
      end
  end.
-endif.

-ifdef(p_seq).
-spec p_seq([parse_fun()]) -> parse_fun().
p_seq(P) ->
  fun(Input, Index) ->
      p_all(P, Input, Index, [])
  end.

-spec p_all([parse_fun()], input(), index(), [term()]) -> parse_result().
p_all([], Inp, Index, Accum ) -> {lists:reverse( Accum ), Inp, Index};
p_all([P|Parsers], Inp, Index, Accum) ->
  case P(Inp, Index) of
    {fail, _} = Failure -> Failure;
    {Result, InpRem, NewIndex} -> p_all(Parsers, InpRem, NewIndex, [Result|Accum])
  end.
-endif.

-ifdef(p_choose).
-spec p_choose([parse_fun()]) -> parse_fun().
p_choose(Parsers) ->
  fun(Input, Index) ->
      p_attempt(Parsers, Input, Index, none)
  end.

-spec p_attempt([parse_fun()], input(), index(), none | parse_failure()) -> parse_result().
p_attempt([], _Input, _Index, Failure) -> Failure;
p_attempt([P|Parsers], Input, Index, FirstFailure)->
  case P(Input, Index) of
    {fail, _} = Failure ->
      case FirstFailure of
        none -> p_attempt(Parsers, Input, Index, Failure);
        _ -> p_attempt(Parsers, Input, Index, FirstFailure)
      end;
    Result -> Result
  end.
-endif.

-ifdef(p_zero_or_more).
-spec p_zero_or_more(parse_fun()) -> parse_fun().
p_zero_or_more(P) ->
  fun(Input, Index) ->
      p_scan(P, Input, Index, [])
  end.
-endif.

-ifdef(p_one_or_more).
-spec p_one_or_more(parse_fun()) -> parse_fun().
p_one_or_more(P) ->
  fun(Input, Index)->
      Result = p_scan(P, Input, Index, []),
      case Result of
        {[_|_], _, _} ->
          Result;
        _ ->
          {fail, {expected, Failure, _}} = P(Input,Index),
          {fail, {expected, {at_least_one, Failure}, Index}}
      end
  end.
-endif.

-ifdef(p_label).
-spec p_label(atom(), parse_fun()) -> parse_fun().
p_label(Tag, P) ->
  fun(Input, Index) ->
      case P(Input, Index) of
        {fail,_} = Failure ->
           Failure;
        {Result, InpRem, NewIndex} ->
          {{Tag, Result}, InpRem, NewIndex}
      end
  end.
-endif.

-ifdef(p_scan).
-spec p_scan(parse_fun(), input(), index(), [term()]) -> {[term()], input(), index()}.
p_scan(_, <<>>, Index, Accum) -> {lists:reverse(Accum), <<>>, Index};
p_scan(P, Inp, Index, Accum) ->
  case P(Inp, Index) of
    {fail,_} -> {lists:reverse(Accum), Inp, Index};
    {Result, InpRem, NewIndex} -> p_scan(P, InpRem, NewIndex, [Result | Accum])
  end.
-endif.

-ifdef(p_string).
-spec p_string(binary()) -> parse_fun().
p_string(S) ->
    Length = erlang:byte_size(S),
    fun(Input, Index) ->
      try
          <<S:Length/binary, Rest/binary>> = Input,
          {S, Rest, p_advance_index(S, Index)}
      catch
          error:{badmatch,_} -> {fail, {expected, {string, S}, Index}}
      end
    end.
-endif.

-ifdef(p_anything).
-spec p_anything() -> parse_fun().
p_anything() ->
  fun(<<>>, Index) -> {fail, {expected, any_character, Index}};
     (Input, Index) when is_binary(Input) ->
          <<C/utf8, Rest/binary>> = Input,
          {<<C/utf8>>, Rest, p_advance_index(<<C/utf8>>, Index)}
  end.
-endif.

-ifdef(p_charclass).
-spec p_charclass(string() | binary()) -> parse_fun().
p_charclass(Class) ->
    {ok, RE} = re:compile(Class, [unicode, dotall]),
    fun(Inp, Index) ->
            case re:run(Inp, RE, [anchored]) of
                {match, [{0, Length}|_]} ->
                    {Head, Tail} = erlang:split_binary(Inp, Length),
                    {Head, Tail, p_advance_index(Head, Index)};
                _ -> {fail, {expected, {character_class, binary_to_list(Class)}, Index}}
            end
    end.
-endif.

-ifdef(p_regexp).
-spec p_regexp(binary()) -> parse_fun().
p_regexp(Regexp) ->
    {ok, RE} = re:compile(Regexp, [unicode, dotall, anchored]),
    fun(Inp, Index) ->
        case re:run(Inp, RE) of
            {match, [{0, Length}|_]} ->
                {Head, Tail} = erlang:split_binary(Inp, Length),
                {Head, Tail, p_advance_index(Head, Index)};
            _ -> {fail, {expected, {regexp, binary_to_list(Regexp)}, Index}}
        end
    end.
-endif.

-ifdef(line).
-spec line(index() | term()) -> pos_integer() | undefined.
line({{line,L},_}) -> L;
line(_) -> undefined.
-endif.

-ifdef(column).
-spec column(index() | term()) -> pos_integer() | undefined.
column({_,{column,C}}) -> C;
column(_) -> undefined.
-endif.

-spec p_advance_index(input() | unicode:charlist() | pos_integer(), index()) -> index().
p_advance_index(MatchedInput, Index) when is_list(MatchedInput) orelse is_binary(MatchedInput)-> % strings
  lists:foldl(fun p_advance_index/2, Index, unicode:characters_to_list(MatchedInput));
p_advance_index(MatchedInput, Index) when is_integer(MatchedInput) -> % single characters
  {{line, Line}, {column, Col}} = Index,
  case MatchedInput of
    $\n -> {{line, Line+1}, {column, 1}};
    _ -> {{line, Line}, {column, Col+1}}
  end.
