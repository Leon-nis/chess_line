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
  spawn{kind: PieceKind, advanced: U32}
}

type InputState {
  waiting_input{}
  input_received{}
  input_updated{}
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
    white_input: InputState,
    black_input: InputState,
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
  select_white_pawn_advanced{}
  select_white_bishop{}
  select_white_knight{}
  select_white_rook{}
  select_white_queen{}
  select_white_pass{}
  select_black_pawn{}
  select_black_pawn_advanced{}
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
    waiting_input{},
    waiting_input{},
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
      spawn{pawn{}, 0}
    case select_white_pawn_advanced{}:
      spawn{pawn{}, 1}
    case select_white_bishop{}:
      spawn{bishop{}, 0}
    case select_white_knight{}:
      spawn{knight{}, 0}
    case select_white_rook{}:
      spawn{rook{}, 0}
    case select_white_queen{}:
      spawn{queen{}, 0}
    case select_white_pass{}:
      pass{}
    case _:
      waiting{}

def action_from_black(event: Event) -> Action:
  match event:
    case select_black_pawn{}:
      spawn{pawn{}, 0}
    case select_black_pawn_advanced{}:
      spawn{pawn{}, 1}
    case select_black_bishop{}:
      spawn{bishop{}, 0}
    case select_black_knight{}:
      spawn{knight{}, 0}
    case select_black_rook{}:
      spawn{rook{}, 0}
    case select_black_queen{}:
      spawn{queen{}, 0}
    case select_black_pass{}:
      pass{}
    case _:
      waiting{}

def on_key(code: U32) -> Event:
  match code:
    case 65:
      select_white_pawn{}
    case 90:
      select_white_pawn_advanced{}
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
    case 77:
      select_black_pawn_advanced{}
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
    case turn{number, white_slots, black_slots, white_reserve, black_reserve, white_pick, black_pick, white_input, black_input, last_white, last_black, summary, outcome, stage, stage_ticks, pending_black_reserve, pending_white_action, pending_black_action}:
      commit(on_event_state(event, number, white_slots, black_slots, white_reserve, black_reserve, white_pick, black_pick, white_input, black_input, last_white, last_black, summary, outcome, stage, stage_ticks, pending_black_reserve, pending_white_action, pending_black_action))

def on_event_state(
  event: Event,
  number: U32,
  white_slots: List(Maybe(Piece)),
  black_slots: List(Maybe(Piece)),
  white_reserve: Reserve,
  black_reserve: Reserve,
  white_pick: Action,
  black_pick: Action,
  white_input: InputState,
  black_input: InputState,
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
      on_event_tick(number, white_slots, black_slots, white_reserve, black_reserve, white_pick, black_pick, white_input, black_input, last_white, last_black, summary, outcome, stage, stage_ticks, pending_black_reserve, pending_white_action, pending_black_action)
    case restart{}:
      initial_state
    case confirm{}:
      on_event_confirm(number, white_slots, black_slots, white_reserve, black_reserve, white_pick, black_pick, white_input, black_input, last_white, last_black, summary, outcome, stage, stage_ticks, pending_black_reserve, pending_white_action, pending_black_action)
    case _:
      on_event_select(event, number, white_slots, black_slots, white_reserve, black_reserve, white_pick, black_pick, white_input, black_input, last_white, last_black, summary, outcome, stage, stage_ticks, pending_black_reserve, pending_white_action, pending_black_action)

def on_event_tick(
  number: U32,
  white_slots: List(Maybe(Piece)),
  black_slots: List(Maybe(Piece)),
  white_reserve: Reserve,
  black_reserve: Reserve,
  white_pick: Action,
  black_pick: Action,
  white_input: InputState,
  black_input: InputState,
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
      turn{number, tick_slots(white_slots), tick_slots(black_slots), white_reserve, black_reserve, white_pick, black_pick, white_input, black_input, last_white, last_black, summary, outcome, planning{}, 0, pending_black_reserve, pending_white_action, pending_black_action}
    case white_turn{}:
      tick_white_preview(number, white_slots, black_slots, white_reserve, black_reserve, white_pick, black_pick, white_input, black_input, last_white, last_black, summary, outcome, stage_ticks, pending_black_reserve, pending_white_action, pending_black_action)
    case black_turn{}:
      tick_black_preview(number, white_slots, black_slots, white_reserve, black_reserve, white_pick, black_pick, white_input, black_input, last_white, last_black, summary, outcome, stage_ticks)

def tick_white_preview(
  number: U32,
  white_slots: List(Maybe(Piece)),
  black_slots: List(Maybe(Piece)),
  white_reserve: Reserve,
  black_reserve: Reserve,
  white_pick: Action,
  black_pick: Action,
  white_input: InputState,
  black_input: InputState,
  last_white: Action,
  last_black: Action,
  summary: String,
  outcome: Outcome,
  stage_ticks: U32,
  pending_black_reserve: Reserve,
  pending_white_action: Action,
  pending_black_action: Action
) -> TurnState:
  tick_white_preview_step(number, tick_slots(white_slots), tick_slots(black_slots), white_reserve, black_reserve, white_pick, black_pick, white_input, black_input, last_white, last_black, summary, outcome, stage_ticks, pending_black_reserve, pending_white_action, pending_black_action, stage_ticks <= tick_ms)

def tick_white_preview_step(
  number: U32,
  white_slots: List(Maybe(Piece)),
  black_slots: List(Maybe(Piece)),
  white_reserve: Reserve,
  black_reserve: Reserve,
  white_pick: Action,
  black_pick: Action,
  white_input: InputState,
  black_input: InputState,
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
      turn{number, white_slots, black_slots, white_reserve, black_reserve, white_pick, black_pick, white_input, black_input, last_white, last_black, summary, outcome, white_turn{}, stage_ticks - tick_ms, pending_black_reserve, pending_white_action, pending_black_action}
    case _:
      resolve_black_phase(number, white_slots, black_slots, white_reserve, pending_black_reserve, white_pick, black_pick, white_input, black_input, pending_white_action, pending_black_action)

def tick_black_preview(
  number: U32,
  white_slots: List(Maybe(Piece)),
  black_slots: List(Maybe(Piece)),
  white_reserve: Reserve,
  black_reserve: Reserve,
  white_pick: Action,
  black_pick: Action,
  white_input: InputState,
  black_input: InputState,
  last_white: Action,
  last_black: Action,
  summary: String,
  outcome: Outcome,
  stage_ticks: U32
) -> TurnState:
  tick_black_preview_step(number, tick_slots(white_slots), tick_slots(black_slots), white_reserve, black_reserve, white_pick, black_pick, white_input, black_input, last_white, last_black, summary, outcome, stage_ticks, stage_ticks <= tick_ms)

def tick_black_preview_step(
  number: U32,
  white_slots: List(Maybe(Piece)),
  black_slots: List(Maybe(Piece)),
  white_reserve: Reserve,
  black_reserve: Reserve,
  white_pick: Action,
  black_pick: Action,
  white_input: InputState,
  black_input: InputState,
  last_white: Action,
  last_black: Action,
  summary: String,
  outcome: Outcome,
  stage_ticks: U32,
  finish: U32
) -> TurnState:
  match finish:
    case 0:
      turn{number, white_slots, black_slots, white_reserve, black_reserve, white_pick, black_pick, white_input, black_input, last_white, last_black, summary, outcome, black_turn{}, stage_ticks - tick_ms, reserve{0, 0, 0, 0, 0}, pass{}, pass{}}
    case _:
      turn{number, white_slots, black_slots, white_reserve, black_reserve, white_pick, black_pick, white_input, black_input, last_white, last_black, summary, outcome, planning{}, 0, reserve{0, 0, 0, 0, 0}, pass{}, pass{}}

def on_event_confirm(
  number: U32,
  white_slots: List(Maybe(Piece)),
  black_slots: List(Maybe(Piece)),
  white_reserve: Reserve,
  black_reserve: Reserve,
  white_pick: Action,
  black_pick: Action,
  white_input: InputState,
  black_input: InputState,
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
  on_event_confirm_by_state(outcome, stage, number, white_slots, black_slots, white_reserve, black_reserve, white_pick, black_pick, white_input, black_input, last_white, last_black, summary, stage_ticks, pending_black_reserve, pending_white_action, pending_black_action)

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
  white_input: InputState,
  black_input: InputState,
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
      on_event_confirm_playing(stage, number, white_slots, black_slots, white_reserve, black_reserve, white_pick, black_pick, white_input, black_input, last_white, last_black, summary, stage_ticks, pending_black_reserve, pending_white_action, pending_black_action)
    case _:
      turn{number, white_slots, black_slots, white_reserve, black_reserve, white_pick, black_pick, white_input, black_input, last_white, last_black, summary, outcome, stage, stage_ticks, pending_black_reserve, pending_white_action, pending_black_action}

def on_event_confirm_playing(
  stage: ResolveStage,
  number: U32,
  white_slots: List(Maybe(Piece)),
  black_slots: List(Maybe(Piece)),
  white_reserve: Reserve,
  black_reserve: Reserve,
  white_pick: Action,
  black_pick: Action,
  white_input: InputState,
  black_input: InputState,
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
      turn{number, white_slots, black_slots, white_reserve, black_reserve, white_pick, black_pick, white_input, black_input, last_white, last_black, summary, playing{}, stage, stage_ticks, pending_black_reserve, pending_white_action, pending_black_action}

def on_event_select(
  event: Event,
  number: U32,
  white_slots: List(Maybe(Piece)),
  black_slots: List(Maybe(Piece)),
  white_reserve: Reserve,
  black_reserve: Reserve,
  white_pick: Action,
  black_pick: Action,
  white_input: InputState,
  black_input: InputState,
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
  on_event_select_by_state(outcome, stage, event, number, white_slots, black_slots, white_reserve, black_reserve, white_pick, black_pick, white_input, black_input, last_white, last_black, summary, stage_ticks, pending_black_reserve, pending_white_action, pending_black_action)

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
  white_input: InputState,
  black_input: InputState,
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
      on_event_select_playing_stage(stage, event, number, white_slots, black_slots, white_reserve, black_reserve, white_pick, black_pick, white_input, black_input, last_white, last_black, summary, stage_ticks, pending_black_reserve, pending_white_action, pending_black_action)
    case _:
      turn{number, white_slots, black_slots, white_reserve, black_reserve, white_pick, black_pick, white_input, black_input, last_white, last_black, summary, outcome, stage, stage_ticks, pending_black_reserve, pending_white_action, pending_black_action}

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
  white_input: InputState,
  black_input: InputState,
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
      on_event_select_playing(event, number, white_slots, black_slots, white_reserve, black_reserve, white_pick, black_pick, white_input, black_input, last_white, last_black, summary)
    case _:
      update_selection_buffered(action_from_white(event), action_from_black(event), number, white_slots, black_slots, white_reserve, black_reserve, white_pick, black_pick, white_input, black_input, last_white, last_black, summary, stage, stage_ticks, pending_black_reserve, pending_white_action, pending_black_action)

def on_event_select_playing(
  event: Event,
  number: U32,
  white_slots: List(Maybe(Piece)),
  black_slots: List(Maybe(Piece)),
  white_reserve: Reserve,
  black_reserve: Reserve,
  white_pick: Action,
  black_pick: Action,
  white_input: InputState,
  black_input: InputState,
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
    white_input,
    black_input,
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
  white_input: InputState,
  black_input: InputState,
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
    update_input_state(white_pick, white_choice, white_input),
    update_input_state(black_pick, black_choice, black_input),
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

def update_selection_buffered(
  white_choice: Action,
  black_choice: Action,
  number: U32,
  white_slots: List(Maybe(Piece)),
  black_slots: List(Maybe(Piece)),
  white_reserve: Reserve,
  black_reserve: Reserve,
  white_pick: Action,
  black_pick: Action,
  white_input: InputState,
  black_input: InputState,
  last_white: Action,
  last_black: Action,
  summary: String,
  stage: ResolveStage,
  stage_ticks: U32,
  pending_black_reserve: Reserve,
  pending_white_action: Action,
  pending_black_action: Action
) -> TurnState:
  turn{
    number,
    white_slots,
    black_slots,
    white_reserve,
    black_reserve,
    choose_action(white_pick, white_choice),
    choose_action(black_pick, black_choice),
    update_input_state(white_pick, white_choice, white_input),
    update_input_state(black_pick, black_choice, black_input),
    last_white,
    last_black,
    summary,
    playing{},
    stage,
    stage_ticks,
    pending_black_reserve,
    pending_white_action,
    pending_black_action,
  }

def choose_action(current: Action, incoming: Action) -> Action:
  match incoming:
    case waiting{}:
      current
    case pass{}:
      pass{}
    case spawn{kind, advanced}:
      spawn{kind, advanced}

def update_input_state(current: Action, incoming: Action, status: InputState) -> InputState:
  match incoming:
    case waiting{}:
      status
    case pass{}:
      update_input_choice(current, pass{}, status)
    case spawn{kind, advanced}:
      update_input_choice(current, spawn{kind, advanced}, status)

def update_input_choice(current: Action, incoming: Action, status: InputState) -> InputState:
  update_input_changed(current, status, same_action(current, incoming))

def update_input_changed(current: Action, status: InputState, same: U32) -> InputState:
  match same:
    case 0:
      update_input_current(current)
    case _:
      status

def update_input_current(current: Action) -> InputState:
  match current:
    case waiting{}:
      input_received{}
    case _:
      input_updated{}

def same_action(a: Action, b: Action) -> U32:
  match a b:
    case waiting{} waiting{}:
      1
    case pass{} pass{}:
      1
    case spawn{kind_a, advanced_a} spawn{kind_b, advanced_b}:
      same_spawn(kind_a, advanced_a, kind_b, advanced_b)
    case _ _:
      0

def same_spawn(kind_a: PieceKind, advanced_a: U32, kind_b: PieceKind, advanced_b: U32) -> U32:
  same_piece_kind(kind_a, kind_b) & (advanced_a === advanced_b)

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
      turn{number, white_slots, black_slots, white_reserve, black_reserve, waiting{}, waiting{}, waiting_input{}, waiting_input{}, white_real, pass{}, white_phase_summary(white_real, black_real, white_rounds), playing{}, white_turn{}, phase_ms, black_reserve, white_real, black_real}
    case _:
      turn{next_turn(number, mid_outcome), wake_slots(white_slots), wake_slots(black_slots), white_reserve, black_reserve, waiting{}, waiting{}, waiting_input{}, waiting_input{}, white_real, pass{}, white_phase_final_summary(white_real, mid_outcome), mid_outcome, black_turn{}, phase_ms, reserve{0, 0, 0, 0, 0}, pass{}, pass{}}

def resolve_black_phase(
  number: U32,
  white_slots: List(Maybe(Piece)),
  black_slots: List(Maybe(Piece)),
  white_reserve: Reserve,
  black_reserve: Reserve,
  white_pick: Action,
  black_pick: Action,
  white_input: InputState,
  black_input: InputState,
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
    white_pick,
    black_pick,
    white_input,
    black_input,
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
    case spawn{kind, advanced}:
      spawn{kind, advanced}

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

type KnightSpecialResult {
  knight_special_result{
    damages: List(U32),
    found: U32,
  }
}

def spawn_action(side: Side, action: Action, own_slots: List(Maybe(Piece)), enemy_slots: List(Maybe(Piece)), reserve: Reserve) -> SpawnResult:
  match action:
    case pass{}:
      spawn_result{own_slots, reserve}
    case waiting{}:
      spawn_result{own_slots, reserve}
    case spawn{kind, advanced}:
      spawn_piece(side, kind, advanced, own_slots, enemy_slots, reserve)

def spawn_piece(side: Side, kind: PieceKind, advanced: U32, own_slots: List(Maybe(Piece)), enemy_slots: List(Maybe(Piece)), reserve: Reserve) -> SpawnResult:
  spawn_piece_allowed(side, kind, advanced, own_slots, enemy_slots, reserve, reserve_has_piece(reserve, kind))

def spawn_piece_allowed(side: Side, kind: PieceKind, advanced: U32, own_slots: List(Maybe(Piece)), enemy_slots: List(Maybe(Piece)), reserve: Reserve, allowed: U32) -> SpawnResult:
  match allowed:
    case 0:
      spawn_result{own_slots, reserve}
    case _:
      spawn_piece_open(side, kind, own_slots, enemy_slots, reserve, spawn_index(side, kind, advanced, own_slots, enemy_slots))

def spawn_piece_open(side: Side, kind: PieceKind, own_slots: List(Maybe(Piece)), enemy_slots: List(Maybe(Piece)), reserve: Reserve, idx: U32) -> SpawnResult:
  spawn_piece_ready(side, kind, own_slots, reserve, idx, spawn_open_at(own_slots, enemy_slots, idx))

def spawn_piece_ready(side: Side, kind: PieceKind, own_slots: List(Maybe(Piece)), reserve: Reserve, idx: U32, open: U32) -> SpawnResult:
  match open:
    case 0:
      spawn_result{own_slots, reserve}
    case _:
      spawn_result{set_slot(own_slots, idx, some{make_piece(side, kind)}), reserve_consume(reserve, kind)}

def spawn_open_at(own_slots: List(Maybe(Piece)), enemy_slots: List(Maybe(Piece)), idx: U32) -> U32:
  slot_free(get_slot(own_slots, idx), get_slot(enemy_slots, idx))

def slot_free(own: Maybe(Piece), enemy: Maybe(Piece)) -> U32:
  match own enemy:
    case none{} none{}:
      1
    case _ _:
      0

def spawn_index(side: Side, kind: PieceKind, advanced: U32, own_slots: List(Maybe(Piece)), enemy_slots: List(Maybe(Piece))) -> U32:
  match kind:
    case pawn{}:
      pawn_spawn_index(side, advanced, own_slots, enemy_slots)
    case _:
      normal_spawn_index(side)

def pawn_spawn_index(side: Side, advanced: U32, own_slots: List(Maybe(Piece)), enemy_slots: List(Maybe(Piece))) -> U32:
  match advanced:
    case 0:
      normal_spawn_index(side)
    case _:
      pawn_spawn_fallback(side, advanced_spawn_index(side), spawn_open_at(own_slots, enemy_slots, advanced_spawn_index(side)))

def pawn_spawn_fallback(side: Side, advanced_idx: U32, open: U32) -> U32:
  match open:
    case 0:
      normal_spawn_index(side)
    case _:
      advanced_idx

def normal_spawn_index(side: Side) -> U32:
  match side:
    case white{}:
      1
    case black{}:
      8

def advanced_spawn_index(side: Side) -> U32:
  match side:
    case white{}:
      2
    case black{}:
      7

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
  own_opening_damage = collect_attack_damage_from(enemy_side(side), enemy_slots, own_after_spawn, enemy_slots)
  enemy_opening_damage = collect_attack_damage_from(side, own_after_spawn, enemy_slots, own_slots)
  own_after_opening = apply_damage_row(own_after_spawn, own_opening_damage)
  enemy_after_opening = apply_damage_row(enemy_slots, enemy_opening_damage)
  conflicts = resolve_conflicts(side, own_after_opening, enemy_after_opening, 1)
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

def resolve_conflicts(side: Side, own_slots: List(Maybe(Piece)), enemy_slots: List(Maybe(Piece)), rounds: U32) -> ConflictResult:
  resolve_conflicts_step(side, own_slots, enemy_slots, rounds, any_same_slot_duel(own_slots, enemy_slots))

def resolve_conflicts_step(side: Side, own_slots: List(Maybe(Piece)), enemy_slots: List(Maybe(Piece)), rounds: U32, has_duel: U32) -> ConflictResult:
  match has_duel:
    case 0:
      conflict_result{own_slots, enemy_slots, rounds}
    case _:
      resolve_conflicts_round(side, own_slots, enemy_slots, rounds)

def resolve_conflicts_round(side: Side, own_slots: List(Maybe(Piece)), enemy_slots: List(Maybe(Piece)), rounds: U32) -> ConflictResult:
  own_after_battle = apply_damage_row(own_slots, collect_attack_damage(enemy_side(side), enemy_slots, own_slots))
  enemy_after_battle = apply_damage_row(enemy_slots, collect_attack_damage(side, own_slots, enemy_slots))
  resolve_conflicts(side, own_after_battle, enemy_after_battle, rounds + 1)

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

def enemy_side(side: Side) -> Side:
  match side:
    case white{}:
      black{}
    case black{}:
      white{}

def collect_attack_damage(side: Side, attack_slots: List(Maybe(Piece)), defend_slots: List(Maybe(Piece))) -> List(U32):
  collect_attack_damage_at(side, attack_slots, defend_slots, 0, zero_damage_row(), 0)

def collect_attack_damage_from(side: Side, attack_slots: List(Maybe(Piece)), defend_slots: List(Maybe(Piece)), source_slots: List(Maybe(Piece))) -> List(U32):
  collect_attack_damage_at(side, attack_slots, defend_slots, 0, zero_damage_row(), 1)

def collect_attack_damage_at(side: Side, attack_slots: List(Maybe(Piece)), defend_slots: List(Maybe(Piece)), idx: U32, acc: List(U32), knight_advance: U32) -> List(U32):
  collect_attack_damage_stop(side, attack_slots, defend_slots, idx, acc, idx === 10, knight_advance)

def collect_attack_damage_stop(side: Side, attack_slots: List(Maybe(Piece)), defend_slots: List(Maybe(Piece)), idx: U32, acc: List(U32), stop: U32, knight_advance: U32) -> List(U32):
  match stop:
    case 0:
      collect_attack_damage_at(side, attack_slots, defend_slots, idx + 1, collect_attack_cell(side, idx, get_slot(attack_slots, idx), get_slot(defend_slots, idx), defend_slots, acc, knight_advance), knight_advance)
    case _:
      acc

def collect_attack_cell(side: Side, idx: U32, attacker: Maybe(Piece), defender: Maybe(Piece), defend_slots: List(Maybe(Piece)), acc: List(U32), knight_advance: U32) -> List(U32):
  match attacker:
    case none{}:
      acc
    case some{piece{_, kind, _, sleepy, _}}:
      collect_attack_kind(side, kind, idx, defender, defend_slots, acc, sleepy, knight_advance)

def collect_attack_kind(side: Side, kind: PieceKind, idx: U32, defender: Maybe(Piece), defend_slots: List(Maybe(Piece)), acc: List(U32), sleepy: U32, knight_advance: U32) -> List(U32):
  match kind:
    case bishop{}:
      collect_attack_bishop(side, idx, defender, defend_slots, piece_damage(kind), acc)
    case knight{}:
      collect_attack_knight_normal(side, idx, defender, defend_slots, piece_damage(kind), acc, sleepy, knight_advance)
    case _:
      collect_attack_normal(idx, defender, piece_damage(kind), acc)

def collect_attack_bishop(side: Side, idx: U32, defender: Maybe(Piece), defend_slots: List(Maybe(Piece)), dmg: U32, acc: List(U32)) -> List(U32):
  match defender:
    case none{}:
      acc
    case some{piece{_, target_kind, _, _, _}}:
      bishop_chain_damage(side, idx, defend_slots, target_kind, dmg, acc)

def collect_attack_normal(idx: U32, defender: Maybe(Piece), dmg: U32, acc: List(U32)) -> List(U32):
  match defender:
    case none{}:
      acc
    case some{_}:
      add_damage(acc, idx, dmg)

def collect_attack_knight_normal(side: Side, idx: U32, defender: Maybe(Piece), defend_slots: List(Maybe(Piece)), dmg: U32, acc: List(U32), sleepy: U32, knight_advance: U32) -> List(U32):
  collect_attack_knight_active(side, idx, defender, defend_slots, dmg, acc, sleepy === 2, knight_advance)

def collect_attack_knight_active(side: Side, idx: U32, defender: Maybe(Piece), defend_slots: List(Maybe(Piece)), dmg: U32, acc: List(U32), moved: U32, knight_advance: U32) -> List(U32):
  match moved:
    case 0:
      collect_attack_knight_phase(side, idx, defender, defend_slots, dmg, acc)
    case _:
      collect_attack_knight_moved(side, idx, defender, defend_slots, dmg, acc, knight_advance)

def collect_attack_knight_moved(side: Side, idx: U32, defender: Maybe(Piece), defend_slots: List(Maybe(Piece)), dmg: U32, acc: List(U32), knight_advance: U32) -> List(U32):
  match knight_advance:
    case 0:
      acc
    case _:
      collect_attack_knight_phase(side, idx, defender, defend_slots, dmg, acc)

def collect_attack_knight_phase(side: Side, idx: U32, defender: Maybe(Piece), defend_slots: List(Maybe(Piece)), dmg: U32, acc: List(U32)) -> List(U32):
  collect_attack_knight_special(side, idx, defender, defend_slots, dmg, acc, knight_special_damage(side, idx, defend_slots, dmg, acc), knight_special_found(knight_special_damage(side, idx, defend_slots, dmg, acc)))

def collect_attack_knight_special(side: Side, idx: U32, defender: Maybe(Piece), defend_slots: List(Maybe(Piece)), dmg: U32, acc: List(U32), result: KnightSpecialResult, found: U32) -> List(U32):
  match found:
    case 0:
      collect_attack_normal(idx, defender, dmg, acc)
    case _:
      knight_special_damages(result)

def collect_knight_special_damage(side: Side, attack_slots: List(Maybe(Piece)), defend_slots: List(Maybe(Piece))) -> List(U32):
  collect_knight_special_at(side, attack_slots, defend_slots, 0, zero_damage_row())

def collect_knight_special_at(side: Side, attack_slots: List(Maybe(Piece)), defend_slots: List(Maybe(Piece)), idx: U32, acc: List(U32)) -> List(U32):
  collect_knight_special_stop(side, attack_slots, defend_slots, idx, acc, idx === 10)

def collect_knight_special_stop(side: Side, attack_slots: List(Maybe(Piece)), defend_slots: List(Maybe(Piece)), idx: U32, acc: List(U32), stop: U32) -> List(U32):
  match stop:
    case 0:
      collect_knight_special_cell(side, attack_slots, defend_slots, idx, acc, get_slot(attack_slots, idx))
    case _:
      acc

def collect_knight_special_cell(side: Side, attack_slots: List(Maybe(Piece)), defend_slots: List(Maybe(Piece)), idx: U32, acc: List(U32), cell: Maybe(Piece)) -> List(U32):
  match cell:
    case none{}:
      collect_knight_special_at(side, attack_slots, defend_slots, idx + 1, acc)
    case some{piece{_, kind, _, _, _}}:
      collect_knight_special_kind(side, attack_slots, defend_slots, idx, acc, kind)

def collect_knight_special_kind(side: Side, attack_slots: List(Maybe(Piece)), defend_slots: List(Maybe(Piece)), idx: U32, acc: List(U32), kind: PieceKind) -> List(U32):
  match kind:
    case knight{}:
      collect_knight_special_next(side, attack_slots, defend_slots, idx, acc, knight_special_damage(side, idx, defend_slots, piece_damage(kind), acc))
    case _:
      collect_knight_special_at(side, attack_slots, defend_slots, idx + 1, acc)

def knight_special_active(side: Side, idx: U32, source_slots: List(Maybe(Piece)), defend_slots: List(Maybe(Piece))) -> U32:
  match side:
    case white{}:
      knight_special_active_white(idx, source_slots, defend_slots)
    case black{}:
      knight_special_active_black(idx, source_slots, defend_slots)

def knight_special_active_white(idx: U32, source_slots: List(Maybe(Piece)), defend_slots: List(Maybe(Piece))) -> U32:
  knight_special_active_white_prev(idx, source_slots, defend_slots, knight_special_here(source_slots, idx, defend_slots, white{}))

def knight_special_active_white_prev(idx: U32, source_slots: List(Maybe(Piece)), defend_slots: List(Maybe(Piece)), here: U32) -> U32:
  match here:
    case 0:
      knight_special_active_white_edge(idx, source_slots, defend_slots, idx === 0)
    case _:
      1

def knight_special_active_white_edge(idx: U32, source_slots: List(Maybe(Piece)), defend_slots: List(Maybe(Piece)), edge: U32) -> U32:
  match edge:
    case 0:
      knight_special_here(source_slots, idx - 1, defend_slots, white{})
    case _:
      0

def knight_special_active_black(idx: U32, source_slots: List(Maybe(Piece)), defend_slots: List(Maybe(Piece))) -> U32:
  knight_special_active_black_next(idx, source_slots, defend_slots, knight_special_here(source_slots, idx, defend_slots, black{}))

def knight_special_active_black_next(idx: U32, source_slots: List(Maybe(Piece)), defend_slots: List(Maybe(Piece)), here: U32) -> U32:
  match here:
    case 0:
      knight_special_active_black_edge(idx, source_slots, defend_slots, idx === 9)
    case _:
      1

def knight_special_active_black_edge(idx: U32, source_slots: List(Maybe(Piece)), defend_slots: List(Maybe(Piece)), edge: U32) -> U32:
  match edge:
    case 0:
      knight_special_here(source_slots, idx + 1, defend_slots, black{})
    case _:
      0

def knight_special_here(source_slots: List(Maybe(Piece)), idx: U32, defend_slots: List(Maybe(Piece)), side: Side) -> U32:
  knight_special_here_cell(idx, defend_slots, side, get_slot(source_slots, idx))

def knight_special_here_cell(idx: U32, defend_slots: List(Maybe(Piece)), side: Side, cell: Maybe(Piece)) -> U32:
  match cell:
    case none{}:
      0
    case some{piece{_, kind, _, _, _}}:
      knight_special_here_kind(idx, defend_slots, side, kind)

def knight_special_here_kind(idx: U32, defend_slots: List(Maybe(Piece)), side: Side, kind: PieceKind) -> U32:
  match kind:
    case knight{}:
      knight_special_found(knight_special_damage(side, idx, defend_slots, piece_damage(kind), zero_damage_row()))
    case _:
      0

def collect_knight_special_next(side: Side, attack_slots: List(Maybe(Piece)), defend_slots: List(Maybe(Piece)), idx: U32, acc: List(U32), result: KnightSpecialResult) -> List(U32):
  collect_knight_special_found(side, attack_slots, defend_slots, idx, acc, knight_special_damages(result), knight_special_found(result))

def collect_knight_special_found(side: Side, attack_slots: List(Maybe(Piece)), defend_slots: List(Maybe(Piece)), idx: U32, acc: List(U32), damages: List(U32), found: U32) -> List(U32):
  match found:
    case 0:
      collect_knight_special_at(side, attack_slots, defend_slots, idx + 1, acc)
    case _:
      collect_knight_special_at(side, attack_slots, defend_slots, idx + 1, damages)

def knight_special_damage(side: Side, idx: U32, defend_slots: List(Maybe(Piece)), dmg: U32, acc: List(U32)) -> KnightSpecialResult:
  match side:
    case white{}:
      knight_special_white(idx, defend_slots, dmg, acc, 2)
    case black{}:
      knight_special_black(idx, defend_slots, dmg, acc, 2)

def knight_special_damages(result: KnightSpecialResult) -> List(U32):
  match result:
    case knight_special_result{damages, _}:
      damages

def knight_special_found(result: KnightSpecialResult) -> U32:
  match result:
    case knight_special_result{_, found}:
      found

def knight_special_white(idx: U32, defend_slots: List(Maybe(Piece)), dmg: U32, acc: List(U32), dist: U32) -> KnightSpecialResult:
  knight_special_white_stop(idx, defend_slots, dmg, acc, dist, idx + dist + dist >= 10)

def knight_special_white_stop(idx: U32, defend_slots: List(Maybe(Piece)), dmg: U32, acc: List(U32), dist: U32, stop: U32) -> KnightSpecialResult:
  match stop:
    case 0:
      knight_special_white_first(idx, defend_slots, dmg, acc, dist, get_slot(defend_slots, idx))
    case _:
      knight_special_result{acc, 0}

def knight_special_white_first(idx: U32, defend_slots: List(Maybe(Piece)), dmg: U32, acc: List(U32), dist: U32, first: Maybe(Piece)) -> KnightSpecialResult:
  match first:
    case none{}:
      knight_special_white(idx, defend_slots, dmg, acc, dist + 1)
    case some{piece{_, first_kind, _, _, _}}:
      knight_special_white_second(idx, defend_slots, dmg, acc, dist, first_kind, get_slot(defend_slots, idx + dist))

def knight_special_white_second(idx: U32, defend_slots: List(Maybe(Piece)), dmg: U32, acc: List(U32), dist: U32, first_kind: PieceKind, second: Maybe(Piece)) -> KnightSpecialResult:
  match second:
    case none{}:
      knight_special_white(idx, defend_slots, dmg, acc, dist + 1)
    case some{piece{_, second_kind, _, _, _}}:
      knight_special_white_pair(idx, defend_slots, dmg, acc, dist, first_kind, second_kind, get_slot(defend_slots, idx + dist + dist))

def knight_special_white_pair(idx: U32, defend_slots: List(Maybe(Piece)), dmg: U32, acc: List(U32), dist: U32, first_kind: PieceKind, second_kind: PieceKind, third: Maybe(Piece)) -> KnightSpecialResult:
  match third:
    case none{}:
      knight_special_white(idx, defend_slots, dmg, acc, dist + 1)
    case some{piece{_, third_kind, _, _, _}}:
      knight_special_white_royal(idx, defend_slots, dmg, acc, dist, first_kind, second_kind, third_kind, knight_special_pattern(first_kind, second_kind, third_kind))

def knight_special_white_royal(idx: U32, defend_slots: List(Maybe(Piece)), dmg: U32, acc: List(U32), dist: U32, first_kind: PieceKind, second_kind: PieceKind, third_kind: PieceKind, valid: U32) -> KnightSpecialResult:
  match valid:
    case 0:
      knight_special_white(idx, defend_slots, dmg, acc, dist + 1)
    case _:
      knight_special_white_apply(idx, defend_slots, dmg, acc, dist, first_kind, second_kind, third_kind)

def knight_special_white_apply(idx: U32, defend_slots: List(Maybe(Piece)), dmg: U32, acc: List(U32), dist: U32, first_kind: PieceKind, second_kind: PieceKind, third_kind: PieceKind) -> KnightSpecialResult:
  knight_special_result{add_damage(add_damage(add_damage(acc, idx, dmg), idx + dist, dmg), idx + dist + dist, dmg), 1}

def knight_special_black(idx: U32, defend_slots: List(Maybe(Piece)), dmg: U32, acc: List(U32), dist: U32) -> KnightSpecialResult:
  knight_special_black_stop(idx, defend_slots, dmg, acc, dist, idx < dist + dist)

def knight_special_black_stop(idx: U32, defend_slots: List(Maybe(Piece)), dmg: U32, acc: List(U32), dist: U32, stop: U32) -> KnightSpecialResult:
  match stop:
    case 0:
      knight_special_black_first(idx, defend_slots, dmg, acc, dist, get_slot(defend_slots, idx))
    case _:
      knight_special_result{acc, 0}

def knight_special_black_first(idx: U32, defend_slots: List(Maybe(Piece)), dmg: U32, acc: List(U32), dist: U32, first: Maybe(Piece)) -> KnightSpecialResult:
  match first:
    case none{}:
      knight_special_black(idx, defend_slots, dmg, acc, dist + 1)
    case some{piece{_, first_kind, _, _, _}}:
      knight_special_black_second(idx, defend_slots, dmg, acc, dist, first_kind, get_slot(defend_slots, idx - dist))

def knight_special_black_second(idx: U32, defend_slots: List(Maybe(Piece)), dmg: U32, acc: List(U32), dist: U32, first_kind: PieceKind, second: Maybe(Piece)) -> KnightSpecialResult:
  match second:
    case none{}:
      knight_special_black(idx, defend_slots, dmg, acc, dist + 1)
    case some{piece{_, second_kind, _, _, _}}:
      knight_special_black_pair(idx, defend_slots, dmg, acc, dist, first_kind, second_kind, get_slot(defend_slots, idx - dist - dist))

def knight_special_black_pair(idx: U32, defend_slots: List(Maybe(Piece)), dmg: U32, acc: List(U32), dist: U32, first_kind: PieceKind, second_kind: PieceKind, third: Maybe(Piece)) -> KnightSpecialResult:
  match third:
    case none{}:
      knight_special_black(idx, defend_slots, dmg, acc, dist + 1)
    case some{piece{_, third_kind, _, _, _}}:
      knight_special_black_royal(idx, defend_slots, dmg, acc, dist, first_kind, second_kind, third_kind, knight_special_pattern(first_kind, second_kind, third_kind))

def knight_special_black_royal(idx: U32, defend_slots: List(Maybe(Piece)), dmg: U32, acc: List(U32), dist: U32, first_kind: PieceKind, second_kind: PieceKind, third_kind: PieceKind, valid: U32) -> KnightSpecialResult:
  match valid:
    case 0:
      knight_special_black(idx, defend_slots, dmg, acc, dist + 1)
    case _:
      knight_special_black_apply(idx, defend_slots, dmg, acc, dist, first_kind, second_kind, third_kind)

def knight_special_black_apply(idx: U32, defend_slots: List(Maybe(Piece)), dmg: U32, acc: List(U32), dist: U32, first_kind: PieceKind, second_kind: PieceKind, third_kind: PieceKind) -> KnightSpecialResult:
  knight_special_result{add_damage(add_damage(add_damage(acc, idx, dmg), idx - dist, dmg), idx - dist - dist, dmg), 1}

def knight_special_pattern(first_kind: PieceKind, second_kind: PieceKind, third_kind: PieceKind) -> U32:
  knight_special_pattern_front(first_kind, second_kind, third_kind, queen_piece(first_kind))

def knight_special_pattern_front(first_kind: PieceKind, second_kind: PieceKind, third_kind: PieceKind, front_queen: U32) -> U32:
  match front_queen:
    case 0:
      knight_special_pattern_mid(first_kind, second_kind, third_kind, queen_piece(second_kind))
    case _:
      same_piece_kind(second_kind, third_kind) | king_piece(third_kind)

def knight_special_pattern_mid(first_kind: PieceKind, second_kind: PieceKind, third_kind: PieceKind, mid_queen: U32) -> U32:
  match mid_queen:
    case 0:
      same_piece_kind(first_kind, second_kind) & royal_piece(third_kind)
    case _:
      same_piece_kind(first_kind, third_kind) | king_piece(third_kind)

def royal_piece(kind: PieceKind) -> U32:
  match kind:
    case queen{}:
      1
    case king{}:
      1
    case _:
      0

def queen_piece(kind: PieceKind) -> U32:
  match kind:
    case queen{}:
      1
    case _:
      0

def king_piece(kind: PieceKind) -> U32:
  match kind:
    case king{}:
      1
    case _:
      0

def merge_damage_rows(left: List(U32), right: List(U32)) -> List(U32):
  match left:
    case []:
      []
    case left_h<>left_t:
      merge_damage_rows_right(left_h, left_t, right)

def merge_damage_rows_right(left_h: U32, left_t: List(U32), right: List(U32)) -> List(U32):
  match right:
    case []:
      left_h <> left_t
    case right_h<>right_t:
      (left_h + right_h) <> merge_damage_rows(left_t, right_t)

def bishop_chain_damage(side: Side, idx: U32, defend_slots: List(Maybe(Piece)), target_kind: PieceKind, dmg: U32, acc: List(U32)) -> List(U32):
  match side:
    case white{}:
      bishop_chain_white(idx, defend_slots, target_kind, dmg, acc)
    case black{}:
      bishop_chain_black(idx, defend_slots, target_kind, dmg, acc)

def bishop_chain_white(idx: U32, defend_slots: List(Maybe(Piece)), target_kind: PieceKind, dmg: U32, acc: List(U32)) -> List(U32):
  bishop_chain_white_stop(idx, defend_slots, target_kind, dmg, acc, idx === 10)

def bishop_chain_white_stop(idx: U32, defend_slots: List(Maybe(Piece)), target_kind: PieceKind, dmg: U32, acc: List(U32), stop: U32) -> List(U32):
  match stop:
    case 0:
      bishop_chain_white_cell(idx, defend_slots, target_kind, dmg, acc, get_slot(defend_slots, idx))
    case _:
      acc

def bishop_chain_white_cell(idx: U32, defend_slots: List(Maybe(Piece)), target_kind: PieceKind, dmg: U32, acc: List(U32), cell: Maybe(Piece)) -> List(U32):
  match cell:
    case none{}:
      acc
    case some{piece{_, kind, _, _, _}}:
      bishop_chain_white_kind(idx, defend_slots, target_kind, dmg, acc, same_piece_kind(kind, target_kind))

def bishop_chain_white_kind(idx: U32, defend_slots: List(Maybe(Piece)), target_kind: PieceKind, dmg: U32, acc: List(U32), same: U32) -> List(U32):
  match same:
    case 0:
      acc
    case _:
      bishop_chain_white(idx + 1, defend_slots, target_kind, dmg, add_damage(acc, idx, dmg))

def bishop_chain_black(idx: U32, defend_slots: List(Maybe(Piece)), target_kind: PieceKind, dmg: U32, acc: List(U32)) -> List(U32):
  bishop_chain_black_cell(idx, defend_slots, target_kind, dmg, acc, get_slot(defend_slots, idx))

def bishop_chain_black_cell(idx: U32, defend_slots: List(Maybe(Piece)), target_kind: PieceKind, dmg: U32, acc: List(U32), cell: Maybe(Piece)) -> List(U32):
  match cell:
    case none{}:
      acc
    case some{piece{_, kind, _, _, _}}:
      bishop_chain_black_kind(idx, defend_slots, target_kind, dmg, acc, same_piece_kind(kind, target_kind))

def bishop_chain_black_kind(idx: U32, defend_slots: List(Maybe(Piece)), target_kind: PieceKind, dmg: U32, acc: List(U32), same: U32) -> List(U32):
  match same:
    case 0:
      acc
    case _:
      bishop_chain_black_next(idx, defend_slots, target_kind, dmg, add_damage(acc, idx, dmg), idx === 0)

def bishop_chain_black_next(idx: U32, defend_slots: List(Maybe(Piece)), target_kind: PieceKind, dmg: U32, acc: List(U32), edge: U32) -> List(U32):
  match edge:
    case 0:
      bishop_chain_black(idx - 1, defend_slots, target_kind, dmg, acc)
    case _:
      acc

def same_piece_kind(a: PieceKind, b: PieceKind) -> U32:
  match a b:
    case pawn{} pawn{}:
      1
    case bishop{} bishop{}:
      1
    case knight{} knight{}:
      1
    case rook{} rook{}:
      1
    case queen{} queen{}:
      1
    case king{} king{}:
      1
    case _ _:
      0

def zero_damage_row() -> List(U32):
  [0 0 0 0 0 0 0 0 0 0]

def add_damage(damages: List(U32), idx: U32, dmg: U32) -> List(U32):
  set_damage(damages, idx, get_damage(damages, idx) + dmg)

def get_damage(damages: List(U32), idx: U32) -> U32:
  match damages:
    case []:
      0
    case h<>t:
      match idx:
        case 0:
          h
        case _:
          get_damage(t, idx - 1)

def set_damage(damages: List(U32), idx: U32, value: U32) -> List(U32):
  match damages:
    case []:
      []
    case h<>t:
      match idx:
        case 0:
          value <> t
        case _:
          h <> set_damage(t, idx - 1, value)

def apply_damage_row(slots: List(Maybe(Piece)), damages: List(U32)) -> List(Maybe(Piece)):
  match slots:
    case []:
      []
    case slot<>slot_rest:
      match damages:
        case []:
          []
        case dmg<>damage_rest:
          apply_damage_cell(slot, dmg) <> apply_damage_row(slot_rest, damage_rest)

def apply_damage_cell(cell: Maybe(Piece), dmg: U32) -> Maybe(Piece):
  match cell:
    case none{}:
      none{}
    case some{piece{side, kind, hp, sleepy, flash}}:
      apply_damage_piece(side, kind, hp, sleepy, flash, dmg)

def apply_damage_piece(side: Side, kind: PieceKind, hp: U32, sleepy: U32, flash: U32, dmg: U32) -> Maybe(Piece):
  apply_damage_piece_keep(side, kind, hp, sleepy, flash, dmg, dmg === 0)

def apply_damage_piece_keep(side: Side, kind: PieceKind, hp: U32, sleepy: U32, flash: U32, dmg: U32, keep: U32) -> Maybe(Piece):
  match keep:
    case 0:
      survive_piece(side, kind, hp, sleepy, flash_ms, dmg, hp > dmg)
    case _:
      some{piece{side, kind, hp, sleepy, flash}}

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
      some{piece{side, kind, hp, move_piece_sleepy(kind), flash}}

def move_piece_sleepy(kind: PieceKind) -> U32:
  match kind:
    case knight{}:
      2
    case _:
      0

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

def any_same_slot_duel(white_slots: List(Maybe(Piece)), black_slots: List(Maybe(Piece))) -> U32:
  match white_slots:
    case []:
      0
    case white_cell<>white_rest:
      any_same_slot_duel_black(white_cell, white_rest, black_slots)

def any_same_slot_duel_black(white_cell: Maybe(Piece), white_rest: List(Maybe(Piece)), black_slots: List(Maybe(Piece))) -> U32:
  match black_slots:
    case []:
      0
    case black_cell<>black_rest:
      any_same_slot_duel_here(white_rest, black_rest, piece_exists(white_cell) & piece_exists(black_cell))

def any_same_slot_duel_here(white_rest: List(Maybe(Piece)), black_rest: List(Maybe(Piece)), here: U32) -> U32:
  match here:
    case 0:
      any_same_slot_duel(white_rest, black_rest)
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
  match white_slots:
    case []:
      1
    case _<>white_rest:
      battleline_empty_black(white_rest, black_slots)

def battleline_empty_black(white_rest: List(Maybe(Piece)), black_slots: List(Maybe(Piece))) -> U32:
  match black_slots:
    case []:
      1
    case _<>black_rest:
      battleline_empty_lanes(white_rest, black_rest)

def battleline_empty_lanes(white_slots: List(Maybe(Piece)), black_slots: List(Maybe(Piece))) -> U32:
  match white_slots:
    case []:
      1
    case _<>[]:
      1
    case white_cell<>white_rest:
      battleline_empty_lanes_black(white_cell, white_rest, black_slots)

def battleline_empty_lanes_black(white_cell: Maybe(Piece), white_rest: List(Maybe(Piece)), black_slots: List(Maybe(Piece))) -> U32:
  match black_slots:
    case []:
      1
    case _<>[]:
      1
    case black_cell<>black_rest:
      battleline_empty_lane_rest(white_rest, black_rest, piece_exists(white_cell) | piece_exists(black_cell))

def battleline_empty_lane_rest(white_rest: List(Maybe(Piece)), black_rest: List(Maybe(Piece)), occupied: U32) -> U32:
  match occupied:
    case 0:
      battleline_empty_lanes(white_rest, black_rest)
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
    case turn{number, white_slots, black_slots, white_reserve, black_reserve, white_pick, black_pick, white_input, black_input, last_white, last_black, summary, outcome, stage, _, _, _, _}:
      <main class="shell">
        <header class="hero">
          <div class="title-stack">
            <p class="eyebrow">CHESS LINE</p>
            <div class="title-row">
              <h1>Chess Line</h1>
              <span class="beta-tag">BETA</span>
            </div>
            <p class="hero-copy">Simultaneous lane pressure on a restrained conveyor board.</p>
          </div>
          <div class="hero-phase">
            <div class={phase_chip_class(stage, outcome)}>{text{phase_label(stage, outcome, white_slots, black_slots)}}</div>
            <div class="turn-badge">
              <span class="turn-label">TURN</span>
              <strong class="turn-number">{text{show(number)}}</strong>
            </div>
          </div>
        </header>
        <section class="status-grid">
          <div class="status-card white-side">
            <div class="status-top">
              <img class="status-king" src={piece_src(white{}, king{})} alt={piece_alt(white{}, king{})} />
              <div class="status-info">
                <p class="status-label">WHITE</p>
                <p class="status-value">{text{"HP " ++ show(piece_hp_in_slot(white_slots, 0))}}</p>
              </div>
            </div>
            <p class="status-select">{text{hidden_action_label(white_input)}}</p>
          </div>
          <div class="status-card ticker-card center-side">
            <p class="ticker-label">ROUND FEED</p>
            <p class="ticker-copy">{text{summary}}</p>
            <p class="ticker-result">{text{result_copy(outcome)}}</p>
          </div>
          <div class="status-card black-side">
            <div class="status-top">
              <img class="status-king" src={piece_src(black{}, king{})} alt={piece_alt(black{}, king{})} />
              <div class="status-info">
                <p class="status-label">BLACK</p>
                <p class="status-value">{text{"HP " ++ show(piece_hp_in_slot(black_slots, 9))}}</p>
              </div>
            </div>
            <p class="status-select">{text{hidden_action_label(black_input)}}</p>
          </div>
        </section>
        <section class="board-stage">
          <div class="belt-banner">
            <span class="belt-side belt-left">WHITE FILE</span>
            <span class="belt-title">CHESS LINE</span>
            <span class="belt-side belt-right">BLACK FILE</span>
          </div>
          <div class="board-wrap">
            <div class={board_class(stage)}>
              {...render_track(0, white_slots, black_slots)}
            </div>
          </div>
        </section>
        <section class="command-grid">
          <div class="panel white-side">
            <div class="panel-head">
              <h2>White Deck</h2>
              <span class="panel-sub">Deploy map</span>
            </div>
            {render_reserve(white{}, white_reserve)}
            {render_control_map(white{})}
          </div>
          <div class="panel center-side control-center">
            <div class="panel-head">
              <h2>Special Moves</h2>
              <span class="panel-sub">Current build</span>
            </div>
            {render_special_rules()}
            {render_global_controls()}
          </div>
          <div class="panel black-side">
            <div class="panel-head">
              <h2>Black Deck</h2>
              <span class="panel-sub">Deploy map</span>
            </div>
            {render_reserve(black{}, black_reserve)}
            {render_control_map(black{})}
          </div>
        </section>
      </main>

def render_track(idx: U32, white_slots: List(Maybe(Piece)), black_slots: List(Maybe(Piece))) -> List(HTML(Event)):
  match white_slots black_slots:
    case [] []:
      []
    case white_cell<>white_rest black_cell<>black_rest:
      render_cell(idx, white_cell, black_cell) <> render_track(idx + 1, white_rest, black_rest)
    case _ _:
      []

def render_cell(idx: U32, white_cell: Maybe(Piece), black_cell: Maybe(Piece)) -> HTML(Event):
  <div class={cell_class(idx, flash_in_cell(white_cell) | flash_in_cell(black_cell))}>
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

def render_reserve(side: Side, reserve: Reserve) -> HTML(Event):
  match reserve:
    case reserve{pawns, bishops, knights, rooks, queens}:
      <div class="reserve-grid">
        {render_reserve_piece(side, pawn{}, pawns)}
        {render_reserve_piece(side, bishop{}, bishops)}
        {render_reserve_piece(side, knight{}, knights)}
        {render_reserve_piece(side, rook{}, rooks)}
        {render_reserve_piece(side, queen{}, queens)}
      </div>

def render_reserve_piece(side: Side, kind: PieceKind, count: U32) -> HTML(Event):
  <div class="reserve-card">
    <img class="reserve-icon" src={piece_src(side, kind)} alt={piece_alt(side, kind)} />
    <span class="reserve-count">{text{show(count)}}</span>
    <span class="reserve-name">{text{kind_name(kind)}}</span>
  </div>

def render_control_map(side: Side) -> HTML(Event):
  match side:
    case white{}:
      <div class="control-map">
        {render_control_piece(white{}, "A", pawn{}, "rank 1", select_white_pawn{})}
        {render_control_piece(white{}, "Z", pawn{}, "rank 2", select_white_pawn_advanced{})}
        {render_control_piece(white{}, "S", bishop{}, "arc hit", select_white_bishop{})}
        {render_control_piece(white{}, "D", knight{}, "relay strike", select_white_knight{})}
        {render_control_piece(white{}, "F", rook{}, "deploy", select_white_rook{})}
        {render_control_piece(white{}, "G", queen{}, "deploy", select_white_queen{})}
        {render_control_pass(",", "skip", select_white_pass{})}
      </div>
    case black{}:
      <div class="control-map">
        {render_control_piece(black{}, "Y", pawn{}, "rank 8", select_black_pawn{})}
        {render_control_piece(black{}, "M", pawn{}, "rank 7", select_black_pawn_advanced{})}
        {render_control_piece(black{}, "U", bishop{}, "arc hit", select_black_bishop{})}
        {render_control_piece(black{}, "I", knight{}, "relay strike", select_black_knight{})}
        {render_control_piece(black{}, "O", rook{}, "deploy", select_black_rook{})}
        {render_control_piece(black{}, "P", queen{}, "deploy", select_black_queen{})}
        {render_control_pass(".", "skip", select_black_pass{})}
      </div>

def render_control_piece(side: Side, key: String, kind: PieceKind, note: String, event: Event) -> HTML(Event):
  <button class="control-card" on_click={event}>
    <span class="control-key">{text{key}}</span>
    <img class="control-icon" src={piece_src(side, kind)} alt={piece_alt(side, kind)} />
    <div class="control-meta">
      <span class="control-name">{text{kind_name(kind)}}</span>
      <span class="control-note">{text{note}}</span>
    </div>
  </button>

def render_control_pass(key: String, note: String, event: Event) -> HTML(Event):
  <button class="control-card control-pass" on_click={event}>
    <span class="control-key">{text{key}}</span>
    <div class="control-pass-dot"></div>
    <div class="control-meta">
      <span class="control-name">pass</span>
      <span class="control-note">{text{note}}</span>
    </div>
  </button>

def render_special_rules() -> HTML(Event):
  <div class="special-rules">
    {render_special_rule("pawn", piece_src(white{}, pawn{}), "advanced summon", "A/Y summon on rank 1/8. Z/M try rank 2/7, else fall back.")}
    {render_special_rule("bishop", piece_src(white{}, bishop{}), "chain strike", "On clash, hits equal enemy pieces linked forward from the first target.")}
    {render_special_rule("knight", piece_src(white{}, knight{}), "royal relay", "Hits three evenly spaced foes: queen may sit in any slot, while king still works as the last target.")}
  </div>

def render_global_controls() -> HTML(Event):
  <div class="global-controls">
    {render_global_button("Enter", "confirm turn", confirm{})}
    {render_global_button("R", "restart", restart{})}
  </div>

def render_global_button(key: String, note: String, event: Event) -> HTML(Event):
  <button class="global-button" on_click={event}>
    <span class="global-key">{text{key}}</span>
    <span class="global-note">{text{note}}</span>
  </button>

def render_special_rule(name: String, icon: String, title: String, note: String) -> HTML(Event):
  <div class="special-card">
    <img class="special-icon" src={icon} alt={name} />
    <div class="special-copy">
      <span class="special-name">{text{name}}</span>
      <span class="special-title">{text{title}}</span>
      <p class="special-note">{text{note}}</p>
    </div>
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
  match slots:
    case []:
      0
    case h<>t:
      match idx:
        case 0:
          piece_hp_cell(h)
        case _:
          piece_hp_in_slot(t, idx - 1)

def piece_hp_cell(cell: Maybe(Piece)) -> U32:
  match cell:
    case none{}:
      0
    case some{piece{_, _, hp, _, _}}:
      hp

def hidden_action_label(status: InputState) -> String:
  match status:
    case waiting_input{}:
      "waiting"
    case input_received{}:
      "input received"
    case input_updated{}:
      "input updated"

def action_name(action: Action) -> String:
  match action:
    case waiting{}:
      "waiting"
    case pass{}:
      "pass"
    case spawn{kind, advanced}:
      action_name_spawn(kind, advanced)

def action_name_spawn(kind: PieceKind, advanced: U32) -> String:
  match kind:
    case pawn{}:
      match advanced:
        case 0:
          "pawn"
        case _:
          "pawn advanced"
    case _:
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
      any_flash_rest(t, flash_in_cell(h))

def any_flash_rest(t: List(Maybe(Piece)), hit: U32) -> U32:
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

def cell_class(idx: U32, flashing: U32) -> String:
  cell_class_hit(idx, flashing)

def cell_class_hit(idx: U32, flashing: U32) -> String:
  match flashing:
    case 0:
      cell_class_base(idx)
    case _:
      cell_class_base(idx) ++ " hit-cell"

def cell_class_base(idx: U32) -> String:
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
  :root{--bg:#e7dcc7;--bg-2:#d5c6ab;--panel:#f5efe2;--panel-2:#ece2cf;--ink:#241b14;--muted:#6f6253;--line:#b39d80;--accent:#816247;--accent-2:#3b3129;--gold:#b68a48;--white-lane:#f8f2e8;--black-lane:#ddd0bb;--belt:#cab79b;--shadow:rgba(34,24,16,.12)}
  *{box-sizing:border-box}body{margin:0;background:linear-gradient(180deg,var(--bg) 0,var(--bg-2) 100%);color:var(--ink);font-family:Georgia,\"Times New Roman\",serif}
  .page{padding:20px}.shell{max-width:1320px;margin:0 auto;display:grid;gap:16px}
  .asset-preload{position:absolute;width:0;height:0;overflow:hidden;opacity:0;pointer-events:none}.preload-img{width:1px;height:1px}
  h1,h2,p{margin:0}.hero,.status-card,.panel,.board-wrap,.cell,.phase-chip,.turn-badge{border:1px solid var(--line);border-radius:18px}
"

css_b : String = "
  .hero,.status-card,.panel{padding:16px;background:linear-gradient(180deg,var(--panel),var(--panel-2));box-shadow:0 10px 24px var(--shadow)}
  .hero{display:grid;grid-template-columns:1fr auto;gap:14px;align-items:end}
  .eyebrow{color:var(--accent);font-size:11px;letter-spacing:.22em;text-transform:uppercase}
  .title-row{display:flex;align-items:center;gap:12px;flex-wrap:wrap}.beta-tag{padding:5px 10px;border-radius:999px;background:#efe5d4;border:1px solid var(--line);color:var(--accent-2);font-size:11px;letter-spacing:.14em}
  h1{font-size:40px;line-height:.95;text-transform:uppercase;letter-spacing:.04em}.hero-copy{margin-top:8px;color:var(--muted);max-width:560px;line-height:1.45}
  .hero-phase{display:grid;gap:10px;justify-items:end}.phase-chip{padding:10px 14px;background:#ede2cd;font-size:12px;letter-spacing:.16em;text-transform:uppercase}
  .white-phase-chip{background:#efe8dc}
  .black-phase-chip{background:#d7cab6}
  .turn-badge{min-width:124px;padding:12px 14px;background:#efe5d4;display:grid;gap:4px;text-align:right}.turn-label{font-size:11px;letter-spacing:.18em;color:var(--accent)}.turn-number{font-size:34px;line-height:1}
  .status-grid,.command-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:12px}.status-card{display:grid;gap:12px}
  .status-top{display:flex;align-items:center;gap:12px}.status-king{width:58px;height:58px;object-fit:contain;image-rendering:auto;filter:drop-shadow(0 6px 10px rgba(0,0,0,.35))}
  .status-label{font-size:12px;letter-spacing:.18em;color:var(--muted)}.status-value{font-size:28px;font-weight:700}.status-select{padding:9px 11px;border-radius:12px;background:#ece2d1;color:var(--accent-2);text-transform:uppercase;font-size:12px;letter-spacing:.08em}
  .ticker-card{justify-content:center}.ticker-label{font-size:11px;letter-spacing:.18em;color:var(--accent)}.ticker-copy{font-size:15px;line-height:1.4}.ticker-result{color:var(--muted);font-size:12px;letter-spacing:.08em;text-transform:uppercase}
  .white-side{background:linear-gradient(180deg,#f7f1e6,#ece1cf)}.black-side{background:linear-gradient(180deg,#e7dac5,#dbc9b0)}.center-side{background:linear-gradient(180deg,#f2eadc,#e5d8c4)}
"

css_c : String = "
  .board-stage{display:grid;gap:10px}.belt-banner{display:grid;grid-template-columns:1fr auto 1fr;align-items:center;gap:12px;padding:0 8px}
  .belt-side,.belt-title{font-size:12px;letter-spacing:.22em;text-transform:uppercase}.belt-left{text-align:left;color:var(--muted)}.belt-right{text-align:right;color:var(--muted)}.belt-title{text-align:center;color:var(--accent-2)}
  .board-wrap{padding:14px;background:linear-gradient(180deg,#d8c7ad,#ccba9f);box-shadow:0 16px 30px var(--shadow)}
  .board{position:relative;display:grid;grid-template-columns:repeat(10,minmax(96px,1fr));gap:10px;padding:10px;border-radius:16px;background:linear-gradient(180deg,#c5b090,#b69d7b);overflow:hidden;transition:box-shadow .18s ease,transform .18s ease}
  .board:before{content:\"\";position:absolute;inset:14px 10px;background:repeating-linear-gradient(90deg,rgba(255,255,255,.08) 0,rgba(255,255,255,.08) 14px,transparent 14px,transparent 28px);border-radius:12px;pointer-events:none}
  .white-stage-board{box-shadow:0 0 0 2px rgba(129,98,71,.18)}
  .black-stage-board{box-shadow:0 0 0 2px rgba(59,49,41,.18)}
  .cell{position:relative;min-height:206px;padding:12px;background:linear-gradient(180deg,#f5efe4,#e7dac6);overflow:hidden;transition:transform .16s ease,box-shadow .16s ease}
  .cell:after{content:\"\";position:absolute;left:12px;right:12px;bottom:12px;height:4px;border-radius:999px;background:rgba(129,98,71,.14)}
  .hit-cell{box-shadow:inset 0 0 0 1px rgba(182,138,72,.34),0 0 0 1px rgba(255,244,219,.38),0 10px 24px rgba(182,138,72,.18);transform:translateY(-1px)}
  .hit-cell:before{content:\"\";position:absolute;inset:10px;border-radius:14px;background:radial-gradient(circle at center,rgba(255,248,229,.48) 0,rgba(255,227,171,.2) 38%,rgba(255,255,255,0) 78%);animation:cellImpact .4s ease-out 1;pointer-events:none}
  .king-cell{background:linear-gradient(180deg,#e7d8bc,#d8c29f)}.slot-label{font-size:12px;color:var(--muted);letter-spacing:.14em}
  .slot-body{margin-top:10px;min-height:154px;display:flex;align-items:center;justify-content:center}.shared-slot{position:relative;width:100%;height:138px;border-radius:16px;background:rgba(255,255,255,.26);border:1px dashed rgba(129,98,71,.18);display:flex;align-items:center;justify-content:center}
"

css_d : String = "
  .king-slot{height:146px}.ghost{background:rgba(255,255,255,.2);border:1px dashed rgba(129,98,71,.14)}
  .piece-slot{position:absolute;height:88px;width:88px;border-radius:18px;display:flex;align-items:center;justify-content:center;box-shadow:0 10px 18px rgba(0,0,0,.16),inset 0 1px 0 rgba(255,255,255,.22);overflow:visible}
  .solo-piece,.king-piece{position:relative}.clash-slot{position:relative}.clash-piece{top:24px}.clash-left{left:10px}.clash-right{right:10px}
  .white-piece{background:linear-gradient(180deg,#fffdf8,#efe7d7);color:#08111c}.black-piece{background:linear-gradient(180deg,#4b4037,#2f2721);color:#f8f2e6}
  .piece-img{width:52px;height:52px;object-fit:contain}.hp-badge,.dmg-badge{position:absolute;right:10px;min-width:18px;height:18px;padding:0 4px;border-radius:999px;font-size:9px;font-weight:700;display:flex;align-items:center;justify-content:center;line-height:1}
  .dmg-badge{bottom:28px;background:#ebe0cd;color:var(--accent-2);border:1px solid rgba(129,98,71,.18)}
  .hp-badge{bottom:8px;background:#f3e6cf;color:#3b3129;border:1px solid rgba(182,138,72,.28)}
  .panel{display:grid;gap:14px}.panel-head{display:flex;align-items:baseline;justify-content:space-between;gap:8px}.panel-sub{font-size:11px;letter-spacing:.18em;color:var(--muted);text-transform:uppercase}
  .reserve-grid{display:grid;grid-template-columns:repeat(5,minmax(0,1fr));gap:8px}.reserve-card{padding:10px 8px;border-radius:14px;background:rgba(255,255,255,.34);border:1px solid rgba(129,98,71,.14);display:grid;justify-items:center;gap:6px}
  .reserve-icon{width:36px;height:36px;object-fit:contain}.reserve-count{font-size:18px;font-weight:700}.reserve-name{text-transform:uppercase;font-size:10px;letter-spacing:.12em;color:var(--muted)}
  .control-map{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:8px}.control-card{display:grid;grid-template-columns:auto auto 1fr;align-items:center;gap:10px;padding:10px 12px;border-radius:14px;background:rgba(255,255,255,.32);border:1px solid rgba(129,98,71,.12);appearance:none;width:100%;text-align:left;color:inherit;font:inherit;cursor:pointer;transition:transform .12s ease,box-shadow .12s ease,border-color .12s ease}
  .control-card:hover,.control-card:focus-visible{transform:translateY(-1px);box-shadow:0 8px 18px rgba(0,0,0,.08);border-color:rgba(129,98,71,.26);outline:none}
  .control-card:active{transform:translateY(0)}
  .control-key{min-width:36px;height:36px;border-radius:10px;background:#efe5d4;border:1px solid rgba(129,98,71,.22);display:flex;align-items:center;justify-content:center;font-size:14px;font-weight:700}
  .control-icon{width:34px;height:34px;object-fit:contain}.control-meta{display:grid;gap:2px}.control-name{text-transform:uppercase;font-size:11px;letter-spacing:.16em}.control-note{font-size:11px;color:var(--muted)}.control-pass-dot{width:18px;height:18px;border-radius:999px;background:#7d6a55}
  .special-rules{display:grid;gap:10px}.special-card{display:grid;grid-template-columns:auto 1fr;gap:12px;align-items:start;padding:12px;border-radius:14px;background:rgba(255,255,255,.34);border:1px solid rgba(129,98,71,.12)}
  .special-icon{width:40px;height:40px;object-fit:contain}.special-copy{display:grid;gap:2px}.special-name{text-transform:uppercase;font-size:11px;letter-spacing:.18em;color:var(--muted)}.special-title{text-transform:uppercase;font-size:12px;letter-spacing:.12em}.special-note{font-size:12px;line-height:1.4;color:var(--muted)}
"

css_e : String = "
  .control-center{align-content:start}.center-commands{display:grid;gap:10px}.enter-card .control-key,.restart-card .control-key{background:#efe5d4;border-color:rgba(129,98,71,.22)}
  .global-controls{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:8px}.global-button{display:grid;gap:4px;align-items:start;justify-items:start;padding:12px 14px;border-radius:14px;border:1px solid rgba(129,98,71,.14);background:rgba(255,255,255,.32);appearance:none;color:inherit;font:inherit;cursor:pointer;transition:transform .12s ease,box-shadow .12s ease,border-color .12s ease}
  .global-button:hover,.global-button:focus-visible{transform:translateY(-1px);box-shadow:0 8px 18px rgba(0,0,0,.08);border-color:rgba(129,98,71,.26);outline:none}
  .global-button:active{transform:translateY(0)}.global-key{min-width:44px;height:36px;padding:0 12px;border-radius:10px;background:#efe5d4;border:1px solid rgba(129,98,71,.22);display:flex;align-items:center;justify-content:center;font-size:14px;font-weight:700}.global-note{text-transform:uppercase;font-size:11px;letter-spacing:.14em;color:var(--muted)}
  .action-pair{display:grid;grid-template-columns:1fr 1fr;gap:8px}.action-puck{padding:10px 12px;border-radius:14px;border:1px solid rgba(129,98,71,.12);display:grid;gap:4px}.action-side{font-size:11px;letter-spacing:.18em;color:var(--muted)}.action-text{text-transform:uppercase;font-size:12px}
  .hit{animation:damagePulse .42s cubic-bezier(.18,.8,.25,1) 1;box-shadow:0 0 0 1px rgba(255,245,224,.38),0 0 28px rgba(255,214,134,.34),0 10px 18px rgba(0,0,0,.18),inset 0 1px 0 rgba(255,255,255,.22)}@keyframes damagePulse{0%{transform:scale(1);opacity:1}15%{transform:scale(.92) translateY(2px);opacity:.52}35%{transform:scale(1.06) translateY(-3px);opacity:1}55%{transform:scale(.98);opacity:.7}100%{transform:scale(1);opacity:1}}
  @keyframes cellImpact{0%{opacity:0;transform:scale(.86)}35%{opacity:1;transform:scale(1.02)}100%{opacity:0;transform:scale(1.1)}}
  @media (max-width:1080px){.status-grid,.command-grid{grid-template-columns:1fr}.hero{grid-template-columns:1fr}.hero-phase{justify-items:start}.reserve-grid{grid-template-columns:repeat(5,minmax(52px,1fr))}}
  @media (max-width:900px){.page{padding:12px}.board{grid-template-columns:repeat(5,minmax(92px,1fr))}.cell{min-height:188px}.control-map,.global-controls{grid-template-columns:1fr}.belt-banner{grid-template-columns:1fr}.belt-left,.belt-right{text-align:center}}"

css : String =
  css_a ++
  css_b ++
  css_c ++
  css_d ++
  css_e
