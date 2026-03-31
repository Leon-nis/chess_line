import /App/
import /Bool/
import /Char/
import /HTML/
import /U32/show as show

tick_ms  : U32 = 60
flash_ms : U32 = 360
phase_ms : U32 = 420

type Side {
  white{}
  black{}
}

type Territory {
  white_territory{}
  black_territory{}
}

type PieceKind {
  pawn{}
  bishop{}
  knight{}
  rook{}
  queen{}
  king{}
}

type Action {
  waiting{}
  pass{}
  spawn{kind: PieceKind}
}

type Outcome {
  playing{}
  white_win{}
  black_win{}
  draw{}
}

type ResolveStage {
  planning{}
  white_turn{}
  black_turn{}
}

type Reserve {
  reserve{
    pawns: U32,
    bishops: U32,
    knights: U32,
    rooks: U32,
    queens: U32,
  }
}

type Piece {
  piece{
    side: Side,
    kind: PieceKind,
    hp: U32,
    sleepy: U32,
    flash: U32,
  }
}

type TurnState {
  turn{
    number: U32,
    white_slots: List(Maybe(Piece)),
    black_slots: List(Maybe(Piece)),
    white_reserve: Reserve,
    black_reserve: Reserve,
    white_pick: Action,
    black_pick: Action,
    last_white: Action,
    last_black: Action,
    summary: String,
    outcome: Outcome,
    stage: ResolveStage,
    stage_ticks: U32,
    pending_black_reserve: Reserve,
    pending_white_action: Action,
    pending_black_action: Action,
  }
}

main : App = app{TurnState, Event, init, render, on_event, none{}}

type Event {
  select_white_pawn{}
  select_white_bishop{}
  select_white_knight{}
  select_white_rook{}
  select_white_queen{}
  select_white_pass{}
  select_black_pawn{}
  select_black_bishop{}
  select_black_knight{}
  select_black_rook{}
  select_black_queen{}
  select_black_pass{}
  confirm{}
  tick{}
  restart{}
  nop{}
}

initial_state : TurnState =
  turn{
    1,
    white_initial_slots(),
    black_initial_slots(),
    reserve{8, 2, 2, 2, 1},
    reserve{8, 2, 2, 2, 1},
    waiting{},
    waiting{},
    waiting{},
    waiting{},
    "Choose both sides and press Enter.",
    playing{},
    planning{},
    0,
    reserve{0, 0, 0, 0, 0},
    pass{},
    pass{},
  }

init : App/Update(TurnState, Event) =
  update{initial_state, none{}}

def white_initial_slots() -> List(Maybe(Piece)):
  [some{make_piece(white{}, king{})} none{} none{} none{} none{} none{} none{} none{} none{} none{}]

def black_initial_slots() -> List(Maybe(Piece)):
  [none{} none{} none{} none{} none{} none{} none{} none{} none{} some{make_piece(black{}, king{})}]

def make_piece(side: Side, kind: PieceKind) -> Piece:
  piece{side, kind, piece_hp(kind), 1, 0}

def piece_hp(kind: PieceKind) -> U32:
  match kind:
    case pawn{}:
      1
    case bishop{}:
      3
    case knight{}:
      3
    case rook{}:
      5
    case queen{}:
      9
    case king{}:
      4

def piece_damage(kind: PieceKind) -> U32:
  piece_hp(kind)

def action_from_white(event: Event) -> Action:
  match event:
    case select_white_pawn{}:
      spawn{pawn{}}
    case select_white_bishop{}:
      spawn{bishop{}}
    case select_white_knight{}:
      spawn{knight{}}
    case select_white_rook{}:
      spawn{rook{}}
    case select_white_queen{}:
      spawn{queen{}}
    case select_white_pass{}:
      pass{}
    case _:
      waiting{}

def action_from_black(event: Event) -> Action:
  match event:
    case select_black_pawn{}:
      spawn{pawn{}}
    case select_black_bishop{}:
      spawn{bishop{}}
    case select_black_knight{}:
      spawn{knight{}}
    case select_black_rook{}:
      spawn{rook{}}
    case select_black_queen{}:
      spawn{queen{}}
    case select_black_pass{}:
      pass{}
    case _:
      waiting{}

def on_key(code: U32) -> Event:
  match code:
    case 65:
      select_white_pawn{}
    case 83:
      select_white_bishop{}
    case 68:
      select_white_knight{}
    case 70:
      select_white_rook{}
    case 71:
      select_white_queen{}
    case 188:
      select_white_pass{}
    case 89:
      select_black_pawn{}
    case 85:
      select_black_bishop{}
    case 73:
      select_black_knight{}
    case 79:
      select_black_rook{}
    case 80:
      select_black_queen{}
    case 190:
      select_black_pass{}
    case 13:
      confirm{}
    case 82:
      restart{}
    case _:
      nop{}

def commit(state: TurnState) -> App/Update(TurnState, Event):
  update{state, none{}}

def on_event(event: Event, state: TurnState) -> App/Update(TurnState, Event):
  match state:
    case turn{number, white_slots, black_slots, white_reserve, black_reserve, white_pick, black_pick, last_white, last_black, summary, outcome, stage, stage_ticks, pending_black_reserve, pending_white_action, pending_black_action}:
      commit(on_event_state(event, number, white_slots, black_slots, white_reserve, black_reserve, white_pick, black_pick, last_white, last_black, summary, outcome, stage, stage_ticks, pending_black_reserve, pending_white_action, pending_black_action))

def on_event_state(
  event: Event,
  number: U32,
  white_slots: List(Maybe(Piece)),
  black_slots: List(Maybe(Piece)),
  white_reserve: Reserve,
  black_reserve: Reserve,
  white_pick: Action,
  black_pick: Action,
  last_white: Action,
  last_black: Action,
  summary: String,
  outcome: Outcome,
  stage: ResolveStage,
  stage_ticks: U32,
  pending_black_reserve: Reserve,
  pending_white_action: Action,
  pending_black_action: Action
) -> TurnState:
  match event:
    case tick{}:
      on_event_tick(number, white_slots, black_slots, white_reserve, black_reserve, white_pick, black_pick, last_white, last_black, summary, outcome, stage, stage_ticks, pending_black_reserve, pending_white_action, pending_black_action)
    case restart{}:
      initial_state
    case confirm{}:
      on_event_confirm(number, white_slots, black_slots, white_reserve, black_reserve, white_pick, black_pick, last_white, last_black, summary, outcome, stage, stage_ticks, pending_black_reserve, pending_white_action, pending_black_action)
    case _:
      on_event_select(event, number, white_slots, black_slots, white_reserve, black_reserve, white_pick, black_pick, last_white, last_black, summary, outcome, stage, stage_ticks, pending_black_reserve, pending_white_action, pending_black_action)

def on_event_tick(
  number: U32,
  white_slots: List(Maybe(Piece)),
  black_slots: List(Maybe(Piece)),
  white_reserve: Reserve,
  black_reserve: Reserve,
  white_pick: Action,
  black_pick: Action,
  last_white: Action,
  last_black: Action,
  summary: String,
  outcome: Outcome,
  stage: ResolveStage,
  stage_ticks: U32,
  pending_black_reserve: Reserve,
  pending_white_action: Action,
  pending_black_action: Action
) -> TurnState:
  match stage:
    case planning{}:
      turn{number, tick_slots(white_slots), tick_slots(black_slots), white_reserve, black_reserve, white_pick, black_pick, last_white, last_black, summary, outcome, planning{}, 0, pending_black_reserve, pending_white_action, pending_black_action}
    case white_turn{}:
      tick_white_preview(number, white_slots, black_slots, white_reserve, black_reserve, last_white, last_black, summary, outcome, stage_ticks, pending_black_reserve, pending_white_action, pending_black_action)
    case black_turn{}:
      tick_black_preview(number, white_slots, black_slots, white_reserve, black_reserve, last_white, last_black, summary, outcome, stage_ticks)

def tick_white_preview(
  number: U32,
  white_slots: List(Maybe(Piece)),
  black_slots: List(Maybe(Piece)),
  white_reserve: Reserve,
  black_reserve: Reserve,
  last_white: Action,
  last_black: Action,
  summary: String,
  outcome: Outcome,
  stage_ticks: U32,
  pending_black_reserve: Reserve,
  pending_white_action: Action,
  pending_black_action: Action
) -> TurnState:
  tick_white_preview_step(number, tick_slots(white_slots), tick_slots(black_slots), white_reserve, black_reserve, last_white, last_black, summary, outcome, stage_ticks, pending_black_reserve, pending_white_action, pending_black_action, stage_ticks <= tick_ms)

def tick_white_preview_step(
  number: U32,
  white_slots: List(Maybe(Piece)),
  black_slots: List(Maybe(Piece)),
  white_reserve: Reserve,
  black_reserve: Reserve,
  last_white: Action,
  last_black: Action,
  summary: String,
  outcome: Outcome,
  stage_ticks: U32,
  pending_black_reserve: Reserve,
  pending_white_action: Action,
  pending_black_action: Action,
  advance: U32
) -> TurnState:
  match advance:
    case 0:
      turn{number, white_slots, black_slots, white_reserve, black_reserve, waiting{}, waiting{}, last_white, last_black, summary, outcome, white_turn{}, stage_ticks - tick_ms, pending_black_reserve, pending_white_action, pending_black_action}
    case _:
      resolve_black_phase(number, white_slots, black_slots, white_reserve, pending_black_reserve, pending_white_action, pending_black_action)

def tick_black_preview(
  number: U32,
  white_slots: List(Maybe(Piece)),
  black_slots: List(Maybe(Piece)),
  white_reserve: Reserve,
  black_reserve: Reserve,
  last_white: Action,
  last_black: Action,
  summary: String,
  outcome: Outcome,
  stage_ticks: U32
) -> TurnState:
  tick_black_preview_step(number, tick_slots(white_slots), tick_slots(black_slots), white_reserve, black_reserve, last_white, last_black, summary, outcome, stage_ticks, stage_ticks <= tick_ms)

def tick_black_preview_step(
  number: U32,
  white_slots: List(Maybe(Piece)),
  black_slots: List(Maybe(Piece)),
  white_reserve: Reserve,
  black_reserve: Reserve,
  last_white: Action,
  last_black: Action,
  summary: String,
  outcome: Outcome,
  stage_ticks: U32,
  finish: U32
) -> TurnState:
  match finish:
    case 0:
      turn{number, white_slots, black_slots, white_reserve, black_reserve, waiting{}, waiting{}, last_white, last_black, summary, outcome, black_turn{}, stage_ticks - tick_ms, reserve{0, 0, 0, 0, 0}, pass{}, pass{}}
    case _:
      turn{number, white_slots, black_slots, white_reserve, black_reserve, waiting{}, waiting{}, last_white, last_black, summary, outcome, planning{}, 0, reserve{0, 0, 0, 0, 0}, pass{}, pass{}}

def on_event_confirm(
  number: U32,
  white_slots: List(Maybe(Piece)),
  black_slots: List(Maybe(Piece)),
  white_reserve: Reserve,
  black_reserve: Reserve,
  white_pick: Action,
  black_pick: Action,
  last_white: Action,
  last_black: Action,
  summary: String,
  outcome: Outcome,
  stage: ResolveStage,
  stage_ticks: U32,
  pending_black_reserve: Reserve,
  pending_white_action: Action,
  pending_black_action: Action
) -> TurnState:
  on_event_confirm_by_state(outcome, stage, number, white_slots, black_slots, white_reserve, black_reserve, white_pick, black_pick, last_white, last_black, summary, stage_ticks, pending_black_reserve, pending_white_action, pending_black_action)

def on_event_confirm_by_state(
  outcome: Outcome,
  stage: ResolveStage,
  number: U32,
  white_slots: List(Maybe(Piece)),
  black_slots: List(Maybe(Piece)),
  white_reserve: Reserve,
  black_reserve: Reserve,
  white_pick: Action,
  black_pick: Action,
  last_white: Action,
  last_black: Action,
  summary: String,
  stage_ticks: U32,
  pending_black_reserve: Reserve,
  pending_white_action: Action,
  pending_black_action: Action
) -> TurnState:
  match outcome:
    case playing{}:
      on_event_confirm_playing(stage, number, white_slots, black_slots, white_reserve, black_reserve, white_pick, black_pick, last_white, last_black, summary, stage_ticks, pending_black_reserve, pending_white_action, pending_black_action)
    case _:
      turn{number, white_slots, black_slots, white_reserve, black_reserve, white_pick, black_pick, last_white, last_black, summary, outcome, stage, stage_ticks, pending_black_reserve, pending_white_action, pending_black_action}

def on_event_confirm_playing(
  stage: ResolveStage,
  number: U32,
  white_slots: List(Maybe(Piece)),
  black_slots: List(Maybe(Piece)),
  white_reserve: Reserve,
  black_reserve: Reserve,
  white_pick: Action,
  black_pick: Action,
  last_white: Action,
  last_black: Action,
  summary: String,
  stage_ticks: U32,
  pending_black_reserve: Reserve,
  pending_white_action: Action,
  pending_black_action: Action
) -> TurnState:
  match stage:
    case planning{}:
      start_turn_resolution(number, white_slots, black_slots, white_reserve, black_reserve, white_pick, black_pick)
    case _:
      turn{number, white_slots, black_slots, white_reserve, black_reserve, white_pick, black_pick, last_white, last_black, summary, playing{}, stage, stage_ticks, pending_black_reserve, pending_white_action, pending_black_action}

def on_event_select(
  event: Event,
  number: U32,
  white_slots: List(Maybe(Piece)),
  black_slots: List(Maybe(Piece)),
  white_reserve: Reserve,
  black_reserve: Reserve,
  white_pick: Action,
  black_pick: Action,
  last_white: Action,
  last_black: Action,
  summary: String,
  outcome: Outcome,
  stage: ResolveStage,
  stage_ticks: U32,
  pending_black_reserve: Reserve,
  pending_white_action: Action,
  pending_black_action: Action
) -> TurnState:
  on_event_select_by_state(outcome, stage, event, number, white_slots, black_slots, white_reserve, black_reserve, white_pick, black_pick, last_white, last_black, summary, stage_ticks, pending_black_reserve, pending_white_action, pending_black_action)

def on_event_select_by_state(
  outcome: Outcome,
  stage: ResolveStage,
  event: Event,
  number: U32,
  white_slots: List(Maybe(Piece)),
  black_slots: List(Maybe(Piece)),
  white_reserve: Reserve,
  black_reserve: Reserve,
  white_pick: Action,
  black_pick: Action,
  last_white: Action,
  last_black: Action,
  summary: String,
  stage_ticks: U32,
  pending_black_reserve: Reserve,
  pending_white_action: Action,
  pending_black_action: Action
) -> TurnState:
  match outcome:
    case playing{}:
      on_event_select_playing_stage(stage, event, number, white_slots, black_slots, white_reserve, black_reserve, white_pick, black_pick, last_white, last_black, summary, stage_ticks, pending_black_reserve, pending_white_action, pending_black_action)
    case _:
      turn{number, white_slots, black_slots, white_reserve, black_reserve, white_pick, black_pick, last_white, last_black, summary, outcome, stage, stage_ticks, pending_black_reserve, pending_white_action, pending_black_action}

def on_event_select_playing_stage(
  stage: ResolveStage,
  event: Event,
  number: U32,
  white_slots: List(Maybe(Piece)),
  black_slots: List(Maybe(Piece)),
  white_reserve: Reserve,
  black_reserve: Reserve,
  white_pick: Action,
  black_pick: Action,
  last_white: Action,
  last_black: Action,
  summary: String,
  stage_ticks: U32,
  pending_black_reserve: Reserve,
  pending_white_action: Action,
  pending_black_action: Action
) -> TurnState:
  match stage:
    case planning{}:
      on_event_select_playing(event, number, white_slots, black_slots, white_reserve, black_reserve, white_pick, black_pick, last_white, last_black, summary)
    case _:
      turn{number, white_slots, black_slots, white_reserve, black_reserve, white_pick, black_pick, last_white, last_black, summary, playing{}, stage, stage_ticks, pending_black_reserve, pending_white_action, pending_black_action}

def on_event_select_playing(
  event: Event,
  number: U32,
  white_slots: List(Maybe(Piece)),
  black_slots: List(Maybe(Piece)),
  white_reserve: Reserve,
  black_reserve: Reserve,
  white_pick: Action,
  black_pick: Action,
  last_white: Action,
  last_black: Action,
  summary: String
) -> TurnState:
  update_selection(
    action_from_white(event),
    action_from_black(event),
    number,
    white_slots,
    black_slots,
    white_reserve,
    black_reserve,
    white_pick,
    black_pick,
    last_white,
    last_black,
    summary
  )

def update_selection(
  white_choice: Action,
  black_choice: Action,
  number: U32,
  white_slots: List(Maybe(Piece)),
  black_slots: List(Maybe(Piece)),
  white_reserve: Reserve,
  black_reserve: Reserve,
  white_pick: Action,
  black_pick: Action,
  last_white: Action,
  last_black: Action,
  summary: String
) -> TurnState:
  turn{
    number,
    white_slots,
    black_slots,
    white_reserve,
    black_reserve,
    choose_action(white_pick, white_choice),
    choose_action(black_pick, black_choice),
    last_white,
    last_black,
    summary,
    playing{},
    planning{},
    0,
    reserve{0, 0, 0, 0, 0},
    pass{},
    pass{},
  }

def choose_action(current: Action, incoming: Action) -> Action:
  match incoming:
    case waiting{}:
      current
    case pass{}:
      pass{}
    case spawn{kind}:
      spawn{kind}

def start_turn_resolution(
  number: U32,
  white_slots: List(Maybe(Piece)),
  black_slots: List(Maybe(Piece)),
  white_reserve: Reserve,
  black_reserve: Reserve,
  white_pick: Action,
  black_pick: Action
) -> TurnState:
  white_real = normalize_action(white_pick)
  black_real = normalize_action(black_pick)
  white_phase = resolve_phase(white{}, white_real, white_slots, black_slots, white_reserve)
  white_next_slots = phase_own_slots(white_phase)
  black_next_slots = phase_enemy_slots(white_phase)
  white_next_reserve = phase_reserve(white_phase)
  mid_outcome = compute_outcome(wake_slots(white_next_slots), wake_slots(black_next_slots), white_next_reserve, black_reserve)
  start_turn_outcome(number, white_next_slots, black_next_slots, white_next_reserve, black_reserve, white_real, black_real, phase_rounds(white_phase), mid_outcome)

def start_turn_outcome(
  number: U32,
  white_slots: List(Maybe(Piece)),
  black_slots: List(Maybe(Piece)),
  white_reserve: Reserve,
  black_reserve: Reserve,
  white_real: Action,
  black_real: Action,
  white_rounds: U32,
  mid_outcome: Outcome
) -> TurnState:
  match mid_outcome:
    case playing{}:
      turn{number, white_slots, black_slots, white_reserve, black_reserve, waiting{}, waiting{}, white_real, pass{}, white_phase_summary(white_real, black_real, white_rounds), playing{}, white_turn{}, phase_ms, black_reserve, white_real, black_real}
    case _:
      turn{next_turn(number, mid_outcome), wake_slots(white_slots), wake_slots(black_slots), white_reserve, black_reserve, waiting{}, waiting{}, white_real, pass{}, white_phase_final_summary(white_real, mid_outcome), mid_outcome, black_turn{}, phase_ms, reserve{0, 0, 0, 0, 0}, pass{}, pass{}}

def resolve_black_phase(
  number: U32,
  white_slots: List(Maybe(Piece)),
  black_slots: List(Maybe(Piece)),
  white_reserve: Reserve,
  black_reserve: Reserve,
  white_real: Action,
  black_real: Action
) -> TurnState:
  black_phase = resolve_phase(black{}, black_real, black_slots, white_slots, black_reserve)
  white_next_slots = wake_slots(phase_enemy_slots(black_phase))
  black_next_slots = wake_slots(phase_own_slots(black_phase))
  black_next_reserve = phase_reserve(black_phase)
  next_outcome = compute_outcome(white_next_slots, black_next_slots, white_reserve, black_next_reserve)
  turn{
    next_turn(number, next_outcome),
    white_next_slots,
    black_next_slots,
    white_reserve,
    black_next_reserve,
    waiting{},
    waiting{},
    white_real,
    black_real,
    black_phase_summary(white_real, black_real, phase_rounds(black_phase), next_outcome),
    next_outcome,
    black_turn{},
    phase_ms,
    reserve{0, 0, 0, 0, 0},
    pass{},
    pass{},
  }

def normalize_action(action: Action) -> Action:
  match action:
    case waiting{}:
      pass{}
    case pass{}:
      pass{}
    case spawn{kind}:
      spawn{kind}

type SpawnResult {
  spawn_result{
    slots: List(Maybe(Piece)),
    reserve: Reserve,
  }
}

type ConflictResult {
  conflict_result{
    own_slots: List(Maybe(Piece)),
    enemy_slots: List(Maybe(Piece)),
    rounds: U32,
  }
}

type PhaseResult {
  phase_result{
    own_slots: List(Maybe(Piece)),
    enemy_slots: List(Maybe(Piece)),
    reserve: Reserve,
    rounds: U32,
  }
}

def spawn_action(side: Side, action: Action, own_slots: List(Maybe(Piece)), enemy_slots: List(Maybe(Piece)), reserve: Reserve) -> SpawnResult:
  match action:
    case pass{}:
      spawn_result{own_slots, reserve}
    case waiting{}:
      spawn_result{own_slots, reserve}
    case spawn{kind}:
      spawn_piece(side, kind, own_slots, enemy_slots, reserve)

def spawn_piece(side: Side, kind: PieceKind, own_slots: List(Maybe(Piece)), enemy_slots: List(Maybe(Piece)), reserve: Reserve) -> SpawnResult:
  spawn_piece_allowed(side, kind, own_slots, enemy_slots, reserve, reserve_has_piece(reserve, kind))

def spawn_piece_allowed(side: Side, kind: PieceKind, own_slots: List(Maybe(Piece)), enemy_slots: List(Maybe(Piece)), reserve: Reserve, allowed: U32) -> SpawnResult:
  match allowed:
    case 0:
      spawn_result{own_slots, reserve}
    case _:
      spawn_piece_open(side, kind, own_slots, enemy_slots, reserve, spawn_open(side, own_slots, enemy_slots))

def spawn_piece_open(side: Side, kind: PieceKind, own_slots: List(Maybe(Piece)), enemy_slots: List(Maybe(Piece)), reserve: Reserve, open: U32) -> SpawnResult:
  match open:
    case 0:
      spawn_result{own_slots, reserve}
    case _:
      spawn_result{set_slot(own_slots, spawn_index(side), some{make_piece(side, kind)}), reserve_consume(reserve, kind)}

def spawn_open(side: Side, own_slots: List(Maybe(Piece)), enemy_slots: List(Maybe(Piece))) -> U32:
  slot_free(get_slot(own_slots, spawn_index(side)), get_slot(enemy_slots, spawn_index(side)))

def slot_free(own: Maybe(Piece), enemy: Maybe(Piece)) -> U32:
  match own enemy:
    case none{} none{}:
      1
    case _ _:
      0

def spawn_index(side: Side) -> U32:
  match side:
    case white{}:
      1
    case black{}:
      8

def spawn_slots(result: SpawnResult) -> List(Maybe(Piece)):
  match result:
    case spawn_result{slots, _}:
      slots

def spawn_reserve(result: SpawnResult) -> Reserve:
  match result:
    case spawn_result{_, reserve}:
      reserve

def resolve_phase(side: Side, action: Action, own_slots: List(Maybe(Piece)), enemy_slots: List(Maybe(Piece)), reserve: Reserve) -> PhaseResult:
  own_after_move = move_slots(side, own_slots)
  spawned = spawn_action(side, action, own_after_move, enemy_slots, reserve)
  own_after_spawn = spawn_slots(spawned)
  conflicts = resolve_conflicts(own_after_spawn, enemy_slots, 0)
  phase_result{conflict_own_slots(conflicts), conflict_enemy_slots(conflicts), spawn_reserve(spawned), conflict_rounds(conflicts)}

def phase_own_slots(result: PhaseResult) -> List(Maybe(Piece)):
  match result:
    case phase_result{own_slots, _, _, _}:
      own_slots

def phase_enemy_slots(result: PhaseResult) -> List(Maybe(Piece)):
  match result:
    case phase_result{_, enemy_slots, _, _}:
      enemy_slots

def phase_reserve(result: PhaseResult) -> Reserve:
  match result:
    case phase_result{_, _, reserve, _}:
      reserve

def phase_rounds(result: PhaseResult) -> U32:
  match result:
    case phase_result{_, _, _, rounds}:
      rounds

def resolve_conflicts(own_slots: List(Maybe(Piece)), enemy_slots: List(Maybe(Piece)), rounds: U32) -> ConflictResult:
  resolve_conflicts_step(own_slots, enemy_slots, rounds, any_same_slot_duel(0, own_slots, enemy_slots))

def resolve_conflicts_step(own_slots: List(Maybe(Piece)), enemy_slots: List(Maybe(Piece)), rounds: U32, has_duel: U32) -> ConflictResult:
  match has_duel:
    case 0:
      conflict_result{own_slots, enemy_slots, rounds}
    case _:
      resolve_conflicts_round(own_slots, enemy_slots, rounds)

def resolve_conflicts_round(own_slots: List(Maybe(Piece)), enemy_slots: List(Maybe(Piece)), rounds: U32) -> ConflictResult:
  own_after_battle = battle_same(0, own_slots, enemy_slots)
  enemy_after_battle = battle_same(0, enemy_slots, own_slots)
  own_after_flash = mark_damage_same(0, own_slots, enemy_slots, own_after_battle)
  enemy_after_flash = mark_damage_same(0, enemy_slots, own_slots, enemy_after_battle)
  resolve_conflicts(own_after_flash, enemy_after_flash, rounds + 1)

def conflict_own_slots(result: ConflictResult) -> List(Maybe(Piece)):
  match result:
    case conflict_result{own_slots, _, _}:
      own_slots

def conflict_enemy_slots(result: ConflictResult) -> List(Maybe(Piece)):
  match result:
    case conflict_result{_, enemy_slots, _}:
      enemy_slots

def conflict_rounds(result: ConflictResult) -> U32:
  match result:
    case conflict_result{_, _, rounds}:
      rounds

def reserve_has_piece(reserve: Reserve, kind: PieceKind) -> U32:
  match reserve:
    case reserve{pawns, bishops, knights, rooks, queens}:
      reserve_has_piece_kind(kind, pawns, bishops, knights, rooks, queens)

def reserve_has_piece_kind(kind: PieceKind, pawns: U32, bishops: U32, knights: U32, rooks: U32, queens: U32) -> U32:
  match kind:
    case pawn{}:
      pawns > 0
    case bishop{}:
      bishops > 0
    case knight{}:
      knights > 0
    case rook{}:
      rooks > 0
    case queen{}:
      queens > 0
    case king{}:
      0

def reserve_consume(reserve: Reserve, kind: PieceKind) -> Reserve:
  match reserve:
    case reserve{pawns, bishops, knights, rooks, queens}:
      reserve_consume_kind(kind, pawns, bishops, knights, rooks, queens)

def reserve_consume_kind(kind: PieceKind, pawns: U32, bishops: U32, knights: U32, rooks: U32, queens: U32) -> Reserve:
  match kind:
    case pawn{}:
      reserve{pawns - 1, bishops, knights, rooks, queens}
    case bishop{}:
      reserve{pawns, bishops - 1, knights, rooks, queens}
    case knight{}:
      reserve{pawns, bishops, knights - 1, rooks, queens}
    case rook{}:
      reserve{pawns, bishops, knights, rooks - 1, queens}
    case queen{}:
      reserve{pawns, bishops, knights, rooks, queens - 1}
    case king{}:
      reserve{pawns, bishops, knights, rooks, queens}

def move_slots(side: Side, slots: List(Maybe(Piece))) -> List(Maybe(Piece)):
  move_slots_at(side, slots, 0)

def move_slots_at(side: Side, slots: List(Maybe(Piece)), idx: U32) -> List(Maybe(Piece)):
  move_slots_stop(side, slots, idx, idx === 10)

def move_slots_stop(side: Side, slots: List(Maybe(Piece)), idx: U32, stop: U32) -> List(Maybe(Piece)):
  match stop:
    case 0:
      move_slots_step(side, slots, idx)
    case _:
      []

def move_slots_step(side: Side, slots: List(Maybe(Piece)), idx: U32) -> List(Maybe(Piece)):
  move_target_cell(side, slots, idx) <> move_slots_at(side, slots, idx + 1)

def move_target_cell(side: Side, slots: List(Maybe(Piece)), idx: U32) -> Maybe(Piece):
  match side:
    case white{}:
      move_target_white(slots, idx)
    case black{}:
      move_target_black(slots, idx)

def move_target_white(slots: List(Maybe(Piece)), idx: U32) -> Maybe(Piece):
  match idx:
    case 0:
      get_slot(slots, 0)
    case 1:
      stay_or_none(get_slot(slots, 1))
    case 2:
      stay_or_move(get_slot(slots, 2), get_slot(slots, 1))
    case 3:
      stay_or_move(get_slot(slots, 3), get_slot(slots, 2))
    case 4:
      stay_or_move(get_slot(slots, 4), get_slot(slots, 3))
    case 5:
      stay_or_move(get_slot(slots, 5), get_slot(slots, 4))
    case 6:
      stay_or_move(get_slot(slots, 6), get_slot(slots, 5))
    case 7:
      stay_or_move(get_slot(slots, 7), get_slot(slots, 6))
    case 8:
      stay_or_move(get_slot(slots, 8), get_slot(slots, 7))
    case _:
      stay_or_move(get_slot(slots, 9), get_slot(slots, 8))

def move_target_black(slots: List(Maybe(Piece)), idx: U32) -> Maybe(Piece):
  match idx:
    case 0:
      stay_or_move(get_slot(slots, 0), get_slot(slots, 1))
    case 1:
      stay_or_move(get_slot(slots, 1), get_slot(slots, 2))
    case 2:
      stay_or_move(get_slot(slots, 2), get_slot(slots, 3))
    case 3:
      stay_or_move(get_slot(slots, 3), get_slot(slots, 4))
    case 4:
      stay_or_move(get_slot(slots, 4), get_slot(slots, 5))
    case 5:
      stay_or_move(get_slot(slots, 5), get_slot(slots, 6))
    case 6:
      stay_or_move(get_slot(slots, 6), get_slot(slots, 7))
    case 7:
      stay_or_move(get_slot(slots, 7), get_slot(slots, 8))
    case 8:
      stay_or_none(get_slot(slots, 8))
    case _:
      get_slot(slots, 9)

def stay_or_none(cell: Maybe(Piece)) -> Maybe(Piece):
  match cell:
    case none{}:
      none{}
    case some{piece}:
      stay_piece(piece)

def stay_or_move(stay: Maybe(Piece), source: Maybe(Piece)) -> Maybe(Piece):
  match stay:
    case none{}:
      move_source_cell(source)
    case some{piece}:
      stay_or_follow(piece, source)

def stay_or_follow(stay: Piece, source: Maybe(Piece)) -> Maybe(Piece):
  match stay:
    case piece{side, kind, hp, sleepy, flash}:
      stay_or_follow_sleepy(side, kind, hp, sleepy, flash, source, sleepy > 0)

def stay_or_follow_sleepy(side: Side, kind: PieceKind, hp: U32, sleepy: U32, flash: U32, source: Maybe(Piece), stays_here: U32) -> Maybe(Piece):
  match stays_here:
    case 0:
      move_source_cell(source)
    case _:
      some{piece{side, kind, hp, sleepy, flash}}

def stay_piece(piece: Piece) -> Maybe(Piece):
  match piece:
    case piece{side, kind, hp, sleepy, flash}:
      stay_if_sleepy(side, kind, hp, sleepy, flash, sleepy > 0)

def stay_if_sleepy(side: Side, kind: PieceKind, hp: U32, sleepy: U32, flash: U32, sleepy_now: U32) -> Maybe(Piece):
  match sleepy_now:
    case 0:
      none{}
    case _:
      some{piece{side, kind, hp, sleepy, flash}}

def move_source_cell(cell: Maybe(Piece)) -> Maybe(Piece):
  match cell:
    case none{}:
      none{}
    case some{piece}:
      move_source_piece(piece)

def move_source_piece(piece: Piece) -> Maybe(Piece):
  match piece:
    case piece{side, kind, hp, sleepy, flash}:
      move_source_sleepy(side, kind, hp, sleepy, flash, sleepy === 0)

def move_source_sleepy(side: Side, kind: PieceKind, hp: U32, sleepy: U32, flash: U32, can_move: U32) -> Maybe(Piece):
  match can_move:
    case 0:
      none{}
    case _:
      some{piece{side, kind, hp, sleepy, flash}}

def battle_same(idx: U32, own_slots: List(Maybe(Piece)), enemy_slots: List(Maybe(Piece))) -> List(Maybe(Piece)):
  battle_same_stop(idx, own_slots, enemy_slots, idx === 10)

def battle_same_stop(idx: U32, own_slots: List(Maybe(Piece)), enemy_slots: List(Maybe(Piece)), stop: U32) -> List(Maybe(Piece)):
  match stop:
    case 0:
      damage_maybe(get_slot(own_slots, idx), get_slot(enemy_slots, idx)) <> battle_same(idx + 1, own_slots, enemy_slots)
    case _:
      []

def mark_damage_same(idx: U32, own_before: List(Maybe(Piece)), enemy_before: List(Maybe(Piece)), own_after: List(Maybe(Piece))) -> List(Maybe(Piece)):
  mark_damage_same_stop(idx, own_before, enemy_before, own_after, idx === 10)

def mark_damage_same_stop(idx: U32, own_before: List(Maybe(Piece)), enemy_before: List(Maybe(Piece)), own_after: List(Maybe(Piece)), stop: U32) -> List(Maybe(Piece)):
  match stop:
    case 0:
      mark_damage_cell(get_slot(own_before, idx), get_slot(enemy_before, idx), get_slot(own_after, idx)) <> mark_damage_same(idx + 1, own_before, enemy_before, own_after)
    case _:
      []

def battle_white(idx: U32, white_from: List(Maybe(Piece)), black_from: List(Maybe(Piece)), white_slots: List(Maybe(Piece)), black_slots: List(Maybe(Piece))) -> List(Maybe(Piece)):
  battle_white_stop(idx, white_from, black_from, white_slots, black_slots, idx === 10)

def battle_white_stop(idx: U32, white_from: List(Maybe(Piece)), black_from: List(Maybe(Piece)), white_slots: List(Maybe(Piece)), black_slots: List(Maybe(Piece)), stop: U32) -> List(Maybe(Piece)):
  match stop:
    case 0:
      battle_cell_white(idx, white_from, black_from, white_slots, black_slots) <> battle_white(idx + 1, white_from, black_from, white_slots, black_slots)
    case _:
      []

def battle_black(idx: U32, white_from: List(Maybe(Piece)), black_from: List(Maybe(Piece)), white_slots: List(Maybe(Piece)), black_slots: List(Maybe(Piece))) -> List(Maybe(Piece)):
  battle_black_stop(idx, white_from, black_from, white_slots, black_slots, idx === 10)

def battle_black_stop(idx: U32, white_from: List(Maybe(Piece)), black_from: List(Maybe(Piece)), white_slots: List(Maybe(Piece)), black_slots: List(Maybe(Piece)), stop: U32) -> List(Maybe(Piece)):
  match stop:
    case 0:
      battle_cell_black(idx, white_from, black_from, white_slots, black_slots) <> battle_black(idx + 1, white_from, black_from, white_slots, black_slots)
    case _:
      []

def battle_cell_white(idx: U32, white_from: List(Maybe(Piece)), black_from: List(Maybe(Piece)), white_slots: List(Maybe(Piece)), black_slots: List(Maybe(Piece))) -> Maybe(Piece):
  damage_maybe(get_slot(white_slots, idx), battle_foe_white(idx, white_from, black_from, black_slots))

def battle_cell_black(idx: U32, white_from: List(Maybe(Piece)), black_from: List(Maybe(Piece)), white_slots: List(Maybe(Piece)), black_slots: List(Maybe(Piece))) -> Maybe(Piece):
  damage_maybe(get_slot(black_slots, idx), battle_foe_black(idx, white_from, black_from, white_slots))

def battle_foe_white(idx: U32, white_from: List(Maybe(Piece)), black_from: List(Maybe(Piece)), black_slots: List(Maybe(Piece))) -> Maybe(Piece):
  battle_foe_white_cross(idx, white_from, black_from, get_slot(black_slots, idx), piece_exists(get_slot(black_slots, idx)))

def battle_foe_white_cross(idx: U32, white_from: List(Maybe(Piece)), black_from: List(Maybe(Piece)), same_slot: Maybe(Piece), same_here: U32) -> Maybe(Piece):
  match same_here:
    case 0:
      cross_foe_white(idx, white_from, black_from)
    case _:
      same_slot

def cross_foe_white(idx: U32, white_from: List(Maybe(Piece)), black_from: List(Maybe(Piece))) -> Maybe(Piece):
  cross_foe_white_at(idx, white_from, black_from, idx === 0)

def cross_foe_white_at(idx: U32, white_from: List(Maybe(Piece)), black_from: List(Maybe(Piece)), edge: U32) -> Maybe(Piece):
  match edge:
    case 0:
      cross_foe_white_pair(idx, white_from, black_from, crossing_pair(idx - 1, white_from, black_from))
    case _:
      none{}

def cross_foe_white_pair(idx: U32, white_from: List(Maybe(Piece)), black_from: List(Maybe(Piece)), crossed: U32) -> Maybe(Piece):
  match crossed:
    case 0:
      none{}
    case _:
      get_slot(black_from, idx)

def battle_foe_black(idx: U32, white_from: List(Maybe(Piece)), black_from: List(Maybe(Piece)), white_slots: List(Maybe(Piece))) -> Maybe(Piece):
  battle_foe_black_cross(idx, white_from, black_from, get_slot(white_slots, idx), piece_exists(get_slot(white_slots, idx)))

def battle_foe_black_cross(idx: U32, white_from: List(Maybe(Piece)), black_from: List(Maybe(Piece)), same_slot: Maybe(Piece), same_here: U32) -> Maybe(Piece):
  match same_here:
    case 0:
      cross_foe_black(idx, white_from, black_from)
    case _:
      same_slot

def cross_foe_black(idx: U32, white_from: List(Maybe(Piece)), black_from: List(Maybe(Piece))) -> Maybe(Piece):
  cross_foe_black_at(idx, white_from, black_from, idx === 9)

def cross_foe_black_at(idx: U32, white_from: List(Maybe(Piece)), black_from: List(Maybe(Piece)), edge: U32) -> Maybe(Piece):
  match edge:
    case 0:
      cross_foe_black_pair(idx, white_from, black_from, crossing_pair(idx, white_from, black_from))
    case _:
      none{}

def cross_foe_black_pair(idx: U32, white_from: List(Maybe(Piece)), black_from: List(Maybe(Piece)), crossed: U32) -> Maybe(Piece):
  match crossed:
    case 0:
      none{}
    case _:
      get_slot(white_from, idx)

def crossing_pair(idx: U32, white_slots: List(Maybe(Piece)), black_slots: List(Maybe(Piece))) -> U32:
  white_can_step(white_slots, idx) & black_can_step(black_slots, idx + 1)

def white_can_step(slots: List(Maybe(Piece)), idx: U32) -> U32:
  white_can_step_range(slots, idx, (idx > 0) & (idx < 9))

def white_can_step_range(slots: List(Maybe(Piece)), idx: U32, in_range: U32) -> U32:
  match in_range:
    case 0:
      0
    case _:
      can_step_cell(get_slot(slots, idx), get_slot(slots, idx + 1))

def black_can_step(slots: List(Maybe(Piece)), idx: U32) -> U32:
  black_can_step_range(slots, idx, (idx > 0) & (idx < 9))

def black_can_step_range(slots: List(Maybe(Piece)), idx: U32, in_range: U32) -> U32:
  match in_range:
    case 0:
      0
    case _:
      can_step_cell(get_slot(slots, idx), get_slot(slots, idx - 1))

def can_step_cell(source: Maybe(Piece), target: Maybe(Piece)) -> U32:
  piece_can_move(source) & (piece_exists(target) === 0)

def piece_can_move(cell: Maybe(Piece)) -> U32:
  match cell:
    case none{}:
      0
    case some{piece{_, _, _, sleepy, _}}:
      sleepy === 0

def damage_maybe(self: Maybe(Piece), foe: Maybe(Piece)) -> Maybe(Piece):
  match self foe:
    case none{} _:
      none{}
    case some{piece} none{}:
      some{piece}
    case some{piece} some{enemy}:
      damage_piece(piece, enemy)

def damage_piece(self: Piece, foe: Piece) -> Maybe(Piece):
  match self:
    case piece{side, kind, hp, sleepy, flash}:
      damage_piece_hp(side, kind, hp, sleepy, flash, piece_damage_of(foe))

def piece_damage_of(piece: Piece) -> U32:
  match piece:
    case piece{_, kind, _, _, _}:
      piece_damage(kind)

def damage_piece_hp(side: Side, kind: PieceKind, hp: U32, sleepy: U32, flash: U32, dmg: U32) -> Maybe(Piece):
  survive_piece(side, kind, hp, sleepy, flash, dmg, hp > dmg)

def survive_piece(side: Side, kind: PieceKind, hp: U32, sleepy: U32, flash: U32, dmg: U32, alive: U32) -> Maybe(Piece):
  match alive:
    case 0:
      none{}
    case _:
      some{piece{side, kind, hp - dmg, sleepy, flash}}

def mark_damage_white(idx: U32, white_from: List(Maybe(Piece)), black_from: List(Maybe(Piece)), white_before: List(Maybe(Piece)), black_before: List(Maybe(Piece)), white_after: List(Maybe(Piece))) -> List(Maybe(Piece)):
  mark_damage_white_stop(idx, white_from, black_from, white_before, black_before, white_after, idx === 10)

def mark_damage_white_stop(idx: U32, white_from: List(Maybe(Piece)), black_from: List(Maybe(Piece)), white_before: List(Maybe(Piece)), black_before: List(Maybe(Piece)), white_after: List(Maybe(Piece)), stop: U32) -> List(Maybe(Piece)):
  match stop:
    case 0:
      mark_damage_cell(get_slot(white_before, idx), battle_foe_white(idx, white_from, black_from, black_before), get_slot(white_after, idx)) <> mark_damage_white(idx + 1, white_from, black_from, white_before, black_before, white_after)
    case _:
      []

def mark_damage_black(idx: U32, white_from: List(Maybe(Piece)), black_from: List(Maybe(Piece)), black_before: List(Maybe(Piece)), white_before: List(Maybe(Piece)), black_after: List(Maybe(Piece))) -> List(Maybe(Piece)):
  mark_damage_black_stop(idx, white_from, black_from, black_before, white_before, black_after, idx === 10)

def mark_damage_black_stop(idx: U32, white_from: List(Maybe(Piece)), black_from: List(Maybe(Piece)), black_before: List(Maybe(Piece)), white_before: List(Maybe(Piece)), black_after: List(Maybe(Piece)), stop: U32) -> List(Maybe(Piece)):
  match stop:
    case 0:
      mark_damage_cell(get_slot(black_before, idx), battle_foe_black(idx, white_from, black_from, white_before), get_slot(black_after, idx)) <> mark_damage_black(idx + 1, white_from, black_from, black_before, white_before, black_after)
    case _:
      []

def mark_damage_cell(before: Maybe(Piece), foe: Maybe(Piece), after: Maybe(Piece)) -> Maybe(Piece):
  match before foe after:
    case some{piece{side, kind, hp, sleepy, _}} some{_} some{piece{_, _, hp2, sleepy2, _}}:
      some{piece{side, kind, hp2, sleepy2, flash_ms}}
    case some{piece{side, kind, hp, sleepy, _}} some{_} none{}:
      none{}
    case some{piece} none{} some{piece2}:
      some{piece2}
    case none{} _ _:
      none{}
    case _ _ some{piece}:
      some{piece}
    case _ _ none{}:
      none{}

def tick_slots(slots: List(Maybe(Piece))) -> List(Maybe(Piece)):
  match slots:
    case []:
      []
    case h<>t:
      tick_cell(h) <> tick_slots(t)

def tick_cell(cell: Maybe(Piece)) -> Maybe(Piece):
  match cell:
    case none{}:
      none{}
    case some{piece{side, kind, hp, sleepy, flash}}:
      some{piece{side, kind, hp, sleepy, tick_flash(flash)}}

def wake_slots(slots: List(Maybe(Piece))) -> List(Maybe(Piece)):
  match slots:
    case []:
      []
    case h<>t:
      wake_cell(h) <> wake_slots(t)

def wake_cell(cell: Maybe(Piece)) -> Maybe(Piece):
  match cell:
    case none{}:
      none{}
    case some{piece{side, kind, hp, sleepy, flash}}:
      some{piece{side, kind, hp, 0, flash}}

def tick_flash(flash: U32) -> U32:
  tick_flash_stop(flash, flash <= tick_ms)

def tick_flash_stop(flash: U32, stop: U32) -> U32:
  match stop:
    case 0:
      tick_flash_nonzero(flash)
    case _:
      0

def tick_flash_nonzero(flash: U32) -> U32:
  tick_flash_zero(flash, flash === 0)

def tick_flash_zero(flash: U32, zero: U32) -> U32:
  match zero:
    case 0:
      flash - tick_ms
    case _:
      0

def any_same_slot_duel(idx: U32, white_slots: List(Maybe(Piece)), black_slots: List(Maybe(Piece))) -> U32:
  any_same_slot_duel_stop(idx, white_slots, black_slots, idx === 10)

def any_same_slot_duel_stop(idx: U32, white_slots: List(Maybe(Piece)), black_slots: List(Maybe(Piece)), stop: U32) -> U32:
  match stop:
    case 0:
      same_slot_duel_here(idx, white_slots, black_slots, piece_exists(get_slot(white_slots, idx)) & piece_exists(get_slot(black_slots, idx)))
    case _:
      0

def same_slot_duel_here(idx: U32, white_slots: List(Maybe(Piece)), black_slots: List(Maybe(Piece)), here: U32) -> U32:
  match here:
    case 0:
      any_same_slot_duel(idx + 1, white_slots, black_slots)
    case _:
      1

def compute_outcome(white_slots: List(Maybe(Piece)), black_slots: List(Maybe(Piece)), white_reserve: Reserve, black_reserve: Reserve) -> Outcome:
  compute_outcome_kings(king_alive(white_slots, 0), king_alive(black_slots, 9), white_slots, black_slots, white_reserve, black_reserve)

def compute_outcome_kings(white_alive: U32, black_alive: U32, white_slots: List(Maybe(Piece)), black_slots: List(Maybe(Piece)), white_reserve: Reserve, black_reserve: Reserve) -> Outcome:
  match white_alive black_alive:
    case 0 0:
      draw{}
    case 0 _:
      black_win{}
    case _ 0:
      white_win{}
    case _ _:
      compute_outcome_empty(white_slots, black_slots, white_reserve, black_reserve, battleline_empty(white_slots, black_slots) & reserves_empty(white_reserve, black_reserve))

def compute_outcome_empty(white_slots: List(Maybe(Piece)), black_slots: List(Maybe(Piece)), white_reserve: Reserve, black_reserve: Reserve, empty: U32) -> Outcome:
  match empty:
    case 0:
      playing{}
    case _:
      draw{}

def king_alive(slots: List(Maybe(Piece)), idx: U32) -> U32:
  piece_exists(get_slot(slots, idx))

def piece_exists(cell: Maybe(Piece)) -> U32:
  match cell:
    case none{}:
      0
    case some{_}:
      1

def reserves_empty(white_reserve: Reserve, black_reserve: Reserve) -> U32:
  reserve_empty(white_reserve) & reserve_empty(black_reserve)

def reserve_empty(reserve: Reserve) -> U32:
  match reserve:
    case reserve{pawns, bishops, knights, rooks, queens}:
      (pawns === 0) & (bishops === 0) & (knights === 0) & (rooks === 0) & (queens === 0)

def battleline_empty(white_slots: List(Maybe(Piece)), black_slots: List(Maybe(Piece))) -> U32:
  battleline_empty_at(white_slots, black_slots, 1)

def battleline_empty_at(white_slots: List(Maybe(Piece)), black_slots: List(Maybe(Piece)), idx: U32) -> U32:
  battleline_empty_stop(white_slots, black_slots, idx, idx === 9)

def battleline_empty_stop(white_slots: List(Maybe(Piece)), black_slots: List(Maybe(Piece)), idx: U32, stop: U32) -> U32:
  match stop:
    case 0:
      battleline_empty_next(white_slots, black_slots, idx, piece_exists(get_slot(white_slots, idx)) | piece_exists(get_slot(black_slots, idx)))
    case _:
      1

def battleline_empty_next(white_slots: List(Maybe(Piece)), black_slots: List(Maybe(Piece)), idx: U32, occupied: U32) -> U32:
  match occupied:
    case 0:
      battleline_empty_at(white_slots, black_slots, idx + 1)
    case _:
      0

def next_turn(number: U32, outcome: Outcome) -> U32:
  match outcome:
    case playing{}:
      number + 1
    case _:
      number

def get_slot(slots: List(Maybe(Piece)), idx: U32) -> Maybe(Piece):
  match slots:
    case []:
      none{}
    case h<>t:
      get_slot_step(h, t, idx)

def get_slot_step(h: Maybe(Piece), t: List(Maybe(Piece)), idx: U32) -> Maybe(Piece):
  match idx:
    case 0:
      h
    case _:
      get_slot(t, idx - 1)

def set_slot(slots: List(Maybe(Piece)), idx: U32, value: Maybe(Piece)) -> List(Maybe(Piece)):
  match slots:
    case []:
      []
    case h<>t:
      set_slot_step(h, t, idx, value)

def set_slot_step(h: Maybe(Piece), t: List(Maybe(Piece)), idx: U32, value: Maybe(Piece)) -> List(Maybe(Piece)):
  match idx:
    case 0:
      value <> t
    case _:
      h <> set_slot(t, idx - 1, value)

def render(state: TurnState) -> HTML(Event):
  <div class="page" every_ms={tick_ms, tick{}} on_key_down={on_key} tabindex="0" style="outline:none">
    <style>{text{css}}</style>
    {render_asset_preload()}
    {render_game(state)}
  </div>

def render_game(state: TurnState) -> HTML(Event):
  match state:
    case turn{number, white_slots, black_slots, white_reserve, black_reserve, white_pick, black_pick, last_white, last_black, summary, outcome, stage, _, _, _, _}:
      <main class="shell">
        <header class="header">
          <div>
            <p class="eyebrow">CHESS LINE</p>
            <h1>Simultaneous lane battle prototype</h1>
          </div>
          <div class={phase_chip_class(stage, outcome)}>{text{phase_label(stage, outcome, white_slots, black_slots)}}</div>
        </header>
        <section class="hud">
          <div class="hud-card white-side">
            <p class="hud-label">White</p>
            <p class="hud-value">{text{"King HP " ++ show(piece_hp_in_slot(white_slots, 0))}}</p>
            <p class="hud-note">{text{"Selection: " ++ hidden_action_label(white_pick)}}</p>
          </div>
          <div class="hud-card center-side">
            <p class="hud-label">Turn</p>
            <p class="hud-value">{text{show(number)}}</p>
            <p class="hud-note">{text{summary}}</p>
          </div>
          <div class="hud-card black-side">
            <p class="hud-label">Black</p>
            <p class="hud-value">{text{"King HP " ++ show(piece_hp_in_slot(black_slots, 9))}}</p>
            <p class="hud-note">{text{"Selection: " ++ hidden_action_label(black_pick)}}</p>
          </div>
        </section>
        <section class="board-wrap">
          <div class={board_class(stage)}>
            {...render_track(0, white_slots, black_slots)}
          </div>
        </section>
        <section class="meta-grid">
          <div class="panel white-side">
            <h2>White Reserve</h2>
            {render_reserve(white_reserve)}
            <p class="legend">{text{"A pawn · S bishop · D knight · F rook · G queen · , pass"}}</p>
          </div>
          <div class="panel center-side">
            <h2>Resolution</h2>
            <p class="legend">{text{"Enter resolves both sides. R restarts after any result."}}</p>
            <p class="legend">{text{"Last turn: White " ++ action_name(last_white) ++ " / Black " ++ action_name(last_black)}}</p>
            <p class="legend">{text{result_copy(outcome)}}</p>
          </div>
          <div class="panel black-side">
            <h2>Black Reserve</h2>
            {render_reserve(black_reserve)}
            <p class="legend">{text{"Y pawn · U bishop · I knight · O rook · P queen · . pass"}}</p>
          </div>
        </section>
      </main>

def render_track(idx: U32, white_slots: List(Maybe(Piece)), black_slots: List(Maybe(Piece))) -> List(HTML(Event)):
  render_track_stop(idx, white_slots, black_slots, idx === 10)

def render_track_stop(idx: U32, white_slots: List(Maybe(Piece)), black_slots: List(Maybe(Piece)), stop: U32) -> List(HTML(Event)):
  match stop:
    case 0:
      render_cell(idx, get_slot(white_slots, idx), get_slot(black_slots, idx)) <> render_track(idx + 1, white_slots, black_slots)
    case _:
      []

def render_cell(idx: U32, white_cell: Maybe(Piece), black_cell: Maybe(Piece)) -> HTML(Event):
  <div class={cell_class(idx)}>
    <p class="slot-label">{text{slot_label(idx)}}</p>
    <div class="slot-body">
      {render_slot_contents(idx, white_cell, black_cell)}
    </div>
  </div>

def render_slot_contents(idx: U32, white_cell: Maybe(Piece), black_cell: Maybe(Piece)) -> HTML(Event):
  render_slot_contents_kind(slot_kind(idx), white_cell, black_cell)

def render_slot_contents_kind(kind: U32, white_cell: Maybe(Piece), black_cell: Maybe(Piece)) -> HTML(Event):
  match kind:
    case 0:
      render_king_slot(white_cell, black_cell)
    case _:
      render_lane_slot(white_cell, black_cell)

def render_king_slot(white_cell: Maybe(Piece), black_cell: Maybe(Piece)) -> HTML(Event):
  match white_cell black_cell:
    case some{piece} _:
      <div class="shared-slot king-slot">{render_piece(piece, "piece-slot king-piece")}</div>
    case none{} some{piece}:
      <div class="shared-slot king-slot">{render_piece(piece, "piece-slot king-piece")}</div>
    case none{} none{}:
      <div class="shared-slot king-slot ghost"></div>

def render_lane_slot(white_cell: Maybe(Piece), black_cell: Maybe(Piece)) -> HTML(Event):
  match white_cell black_cell:
    case none{} none{}:
      <div class="shared-slot ghost"></div>
    case some{white_piece} none{}:
      <div class="shared-slot">{render_piece(white_piece, "piece-slot solo-piece")}</div>
    case none{} some{black_piece}:
      <div class="shared-slot">{render_piece(black_piece, "piece-slot solo-piece")}</div>
    case some{white_piece} some{black_piece}:
      <div class="shared-slot clash-slot">
        {render_piece(white_piece, "piece-slot clash-piece clash-left")}
        {render_piece(black_piece, "piece-slot clash-piece clash-right")}
      </div>

def render_piece(piece: Piece, cls: String) -> HTML(Event):
  match piece:
    case piece{side, kind, hp, sleepy, flash}:
      <div class={piece_class(side, kind, flash, cls)}>
        <img class="piece-img" src={piece_src(side, kind)} alt={piece_alt(side, kind)} />
        <span class="hp-badge">{text{show(hp)}}</span>
        <span class="dmg-badge">{text{show(piece_damage(kind))}}</span>
      </div>

def render_reserve(reserve: Reserve) -> HTML(Event):
  match reserve:
    case reserve{pawns, bishops, knights, rooks, queens}:
      <div class="reserve-list">
        <div class="reserve-row"><span>Pawn</span><strong>{text{show(pawns)}}</strong></div>
        <div class="reserve-row"><span>Bishop</span><strong>{text{show(bishops)}}</strong></div>
        <div class="reserve-row"><span>Knight</span><strong>{text{show(knights)}}</strong></div>
        <div class="reserve-row"><span>Rook</span><strong>{text{show(rooks)}}</strong></div>
        <div class="reserve-row"><span>Queen</span><strong>{text{show(queens)}}</strong></div>
      </div>

def render_asset_preload() -> HTML(Event):
  <div class="asset-preload" aria-hidden="true">
    {preload_piece(white{}, pawn{})}
    {preload_piece(white{}, bishop{})}
    {preload_piece(white{}, knight{})}
    {preload_piece(white{}, rook{})}
    {preload_piece(white{}, queen{})}
    {preload_piece(white{}, king{})}
    {preload_piece(black{}, pawn{})}
    {preload_piece(black{}, bishop{})}
    {preload_piece(black{}, knight{})}
    {preload_piece(black{}, rook{})}
    {preload_piece(black{}, queen{})}
    {preload_piece(black{}, king{})}
  </div>

def preload_piece(side: Side, kind: PieceKind) -> HTML(Event):
  <img class="preload-img" src={piece_src(side, kind)} alt={piece_alt(side, kind)} />

def piece_hp_in_slot(slots: List(Maybe(Piece)), idx: U32) -> U32:
  piece_hp_cell(get_slot(slots, idx))

def piece_hp_cell(cell: Maybe(Piece)) -> U32:
  match cell:
    case none{}:
      0
    case some{piece{_, _, hp, _, _}}:
      hp

def hidden_action_label(action: Action) -> String:
  match action:
    case waiting{}:
      "waiting"
    case pass{}:
      "pass selected"
    case spawn{_}:
      "spawn selected"

def action_name(action: Action) -> String:
  match action:
    case waiting{}:
      "waiting"
    case pass{}:
      "pass"
    case spawn{kind}:
      kind_name(kind)

def kind_name(kind: PieceKind) -> String:
  match kind:
    case pawn{}:
      "pawn"
    case bishop{}:
      "bishop"
    case knight{}:
      "knight"
    case rook{}:
      "rook"
    case queen{}:
      "queen"
    case king{}:
      "king"

def phase_label(stage: ResolveStage, outcome: Outcome, white_slots: List(Maybe(Piece)), black_slots: List(Maybe(Piece))) -> String:
  match stage outcome:
    case white_turn{} playing{}:
      "White Turn"
    case black_turn{} playing{}:
      "Black Turn"
    case _ _:
      phase_label_outcome(outcome, white_slots, black_slots)

def phase_label_outcome(outcome: Outcome, white_slots: List(Maybe(Piece)), black_slots: List(Maybe(Piece))) -> String:
  match outcome:
    case playing{}:
      phase_playing(any_flash(white_slots) | any_flash(black_slots))
    case white_win{}:
      "White wins"
    case black_win{}:
      "Black wins"
    case draw{}:
      "Draw"

def phase_playing(flashing: U32) -> String:
  match flashing:
    case 0:
      "Planning"
    case _:
      "Damage flash"

def phase_chip_class(stage: ResolveStage, outcome: Outcome) -> String:
  match outcome:
    case playing{}:
      phase_chip_stage(stage)
    case _:
      "phase-chip"

def phase_chip_stage(stage: ResolveStage) -> String:
  match stage:
    case planning{}:
      "phase-chip"
    case white_turn{}:
      "phase-chip white-phase-chip"
    case black_turn{}:
      "phase-chip black-phase-chip"

def board_class(stage: ResolveStage) -> String:
  match stage:
    case planning{}:
      "board"
    case white_turn{}:
      "board white-stage-board"
    case black_turn{}:
      "board black-stage-board"

def any_flash(slots: List(Maybe(Piece))) -> U32:
  match slots:
    case []:
      0
    case h<>t:
      any_flash_rest(h, t, flash_in_cell(h))

def any_flash_rest(h: Maybe(Piece), t: List(Maybe(Piece)), hit: U32) -> U32:
  match hit:
    case 0:
      any_flash(t)
    case _:
      1

def flash_in_cell(cell: Maybe(Piece)) -> U32:
  match cell:
    case none{}:
      0
    case some{piece{_, _, _, _, flash}}:
      flash > 0

def result_copy(outcome: Outcome) -> String:
  match outcome:
    case playing{}:
      "Game in progress."
    case white_win{}:
      "Black king destroyed."
    case black_win{}:
      "White king destroyed."
    case draw{}:
      "Both kings died or both armies ran dry."

def turn_summary(white: Action, black: Action, white_rounds: U32, black_rounds: U32, outcome: Outcome) -> String:
  turn_summary_result(outcome, "White move/spawn/combat x" ++ show(white_rounds) ++ " -> Black move/spawn/combat x" ++ show(black_rounds) ++ " | White " ++ action_name(white) ++ " / Black " ++ action_name(black))

def white_phase_summary(white: Action, black: Action, white_rounds: U32) -> String:
  "White move/spawn/combat x" ++ show(white_rounds) ++ " | White " ++ action_name(white) ++ " / Black " ++ action_name(black) ++ " queued."

def white_phase_final_summary(white: Action, outcome: Outcome) -> String:
  white_phase_final_copy(outcome, "White " ++ action_name(white) ++ " resolved.")

def white_phase_final_copy(outcome: Outcome, prefix: String) -> String:
  match outcome:
    case playing{}:
      prefix
    case white_win{}:
      prefix ++ " White wins."
    case black_win{}:
      prefix ++ " Black wins."
    case draw{}:
      prefix ++ " Draw."

def black_phase_summary(white: Action, black: Action, black_rounds: U32, outcome: Outcome) -> String:
  turn_summary_result(outcome, "White resolved -> Black move/spawn/combat x" ++ show(black_rounds) ++ " | White " ++ action_name(white) ++ " / Black " ++ action_name(black))

def turn_summary_result(outcome: Outcome, prefix: String) -> String:
  match outcome:
    case playing{}:
      prefix ++ " resolved."
    case white_win{}:
      prefix ++ " resolved. White wins."
    case black_win{}:
      prefix ++ " resolved. Black wins."
    case draw{}:
      prefix ++ " resolved. Draw."

def slot_label(idx: U32) -> String:
  match idx:
    case 0:
      "WK"
    case 1:
      "1"
    case 2:
      "2"
    case 3:
      "3"
    case 4:
      "4"
    case 5:
      "5"
    case 6:
      "6"
    case 7:
      "7"
    case 8:
      "8"
    case _:
      "BK"

def slot_kind(idx: U32) -> U32:
  match idx:
    case 0:
      0
    case 9:
      0
    case _:
      1

def cell_class(idx: U32) -> String:
  match idx:
    case 0:
      "cell king-cell white-side"
    case 1:
      "cell lane-cell white-side"
    case 2:
      "cell lane-cell white-side"
    case 3:
      "cell lane-cell white-side"
    case 4:
      "cell lane-cell white-side"
    case 5:
      "cell lane-cell black-side"
    case 6:
      "cell lane-cell black-side"
    case 7:
      "cell lane-cell black-side"
    case 8:
      "cell lane-cell black-side"
    case _:
      "cell king-cell black-side"

def piece_class(side: Side, kind: PieceKind, flash: U32, prefix: String) -> String:
  piece_class_hit(side, kind, flash > 0, prefix)

def piece_class_hit(side: Side, kind: PieceKind, hit: U32, prefix: String) -> String:
  match hit:
    case 0:
      prefix ++ side_class(side) ++ " " ++ kind_name(kind)
    case _:
      prefix ++ side_class(side) ++ " " ++ kind_name(kind) ++ " hit"

def side_class(side: Side) -> String:
  match side:
    case white{}:
      "white-piece"
    case black{}:
      "black-piece"

def piece_src(side: Side, kind: PieceKind) -> String:
  match side kind:
    case white{} pawn{}:
      "assets/W_Pawn.png"
    case white{} bishop{}:
      "assets/W_Bishop.png"
    case white{} knight{}:
      "assets/W_Knight.png"
    case white{} rook{}:
      "assets/W_Rook.png"
    case white{} queen{}:
      "assets/W_Queen.png"
    case white{} king{}:
      "assets/W_King.png"
    case black{} pawn{}:
      "assets/B_Pawn.png"
    case black{} bishop{}:
      "assets/B_Bishop.png"
    case black{} knight{}:
      "assets/B_Knight.png"
    case black{} rook{}:
      "assets/B_Rook.png"
    case black{} queen{}:
      "assets/B_Queen.png"
    case black{} king{}:
      "assets/B_King.png"

def piece_alt(side: Side, kind: PieceKind) -> String:
  side_name(side) ++ " " ++ kind_name(kind)

def side_name(side: Side) -> String:
  match side:
    case white{}:
      "white"
    case black{}:
      "black"

css_a : String = "
  *{box-sizing:border-box}body{margin:0;background:#efe4cf;color:#201913;font-family:Georgia,serif}
  .page{padding:16px}.shell{max-width:1200px;margin:0 auto;display:grid;gap:14px}
  .asset-preload{position:absolute;width:0;height:0;overflow:hidden;opacity:0;pointer-events:none}.preload-img{width:1px;height:1px}
  .header,.hud,.meta-grid{display:grid;gap:10px}.hud,.meta-grid{grid-template-columns:repeat(3,1fr)}
  .header{grid-template-columns:1fr auto}.eyebrow{margin:0;color:#735b46;font-size:12px;letter-spacing:.18em;text-transform:uppercase}
  h1,h2,p{margin:0}.phase-chip,.hud-card,.panel,.cell{border:1px solid rgba(40,25,16,.12);border-radius:18px}
"

css_b : String = "
  .phase-chip,.hud-card,.panel{padding:14px;background:#fffaf2}.phase-chip{font-size:12px;text-transform:uppercase;transition:background .18s ease,transform .18s ease,box-shadow .18s ease}
  .white-phase-chip{background:#fff4d8;box-shadow:0 0 0 2px rgba(214,173,76,.18);transform:translateY(-1px)}
  .black-phase-chip{background:#46372b;color:#f7ecd8;box-shadow:0 0 0 2px rgba(53,38,27,.2);transform:translateY(-1px)}
  .hud-value{font-size:26px;font-weight:700}.hud-note,.legend{margin-top:6px;font-size:14px;line-height:1.35;color:#5c4b3d}
  .white-side{background:#fffdf9}.black-side{background:#332a24;color:#f4eadc}.black-side .hud-note,.black-side .legend{color:#dcccb4}
"

css_c : String = "
  .center-side{background:#f3e3c4}.board{display:grid;grid-template-columns:repeat(10,minmax(92px,1fr));gap:8px;transition:box-shadow .18s ease,transform .18s ease}
  .white-stage-board{box-shadow:0 0 0 3px rgba(219,188,103,.18);transform:translateY(-1px)}
  .black-stage-board{box-shadow:0 0 0 3px rgba(69,54,41,.18);transform:translateY(-1px)}
  .cell{min-height:160px;padding:10px;background:#f8efe1;overflow:hidden}.king-cell{background:#ead39d}.slot-label{font-size:12px;color:#6e5a47}
  .slot-body{margin-top:8px;min-height:126px;display:flex;align-items:center;justify-content:center}.shared-slot{position:relative;width:100%;height:110px;border-radius:16px;background:rgba(255,255,255,.16);border:1px dashed rgba(91,71,52,.18);display:flex;align-items:center;justify-content:center}
"

css_d : String = "
  .king-slot{height:118px}.ghost{background:rgba(255,255,255,.2);border:1px dashed rgba(91,71,52,.2)}
  .piece-slot{position:absolute;height:68px;width:68px;border-radius:14px;display:flex;align-items:center;justify-content:center}
  .solo-piece,.king-piece{position:relative}.clash-slot{position:relative}.clash-piece{top:21px}.clash-left{left:10px}.clash-right{right:10px}
  .white-piece{background:#fff}.black-piece{background:#2b221d}.piece-img{width:40px;height:40px;object-fit:contain}
  .hp-badge,.dmg-badge{position:absolute;right:12px;min-width:13px;height:13px;padding:0 2px;border-radius:99px;font-size:8px;font-weight:700;display:flex;align-items:center;justify-content:center;line-height:1}
  .dmg-badge{bottom:21px;background:#4d86d9;color:#eef5ff}
  .hp-badge{bottom:7px;background:#f3b84b;color:#22170f}
"

css_e : String = "
  .hit{animation:damagePulse .36s cubic-bezier(.18,.8,.25,1) 1}.reserve-list{display:grid;gap:8px}.reserve-row{display:flex;justify-content:space-between;border-bottom:1px solid rgba(84,65,47,.12);padding-bottom:6px}
  @keyframes damagePulse{0%{transform:scale(1);opacity:1}15%{transform:scale(.96);opacity:.3}35%{transform:scale(1.02);opacity:1}55%{transform:scale(.97);opacity:.25}100%{transform:scale(1);opacity:1}}
  @media (max-width:900px){.hud,.meta-grid{grid-template-columns:1fr}.board{grid-template-columns:repeat(5,minmax(88px,1fr))}}"

css : String =
  css_a ++
  css_b ++
  css_c ++
  css_d ++
  css_e
