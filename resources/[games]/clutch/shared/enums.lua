---@alias MatchState 'waiting' | 'started' | 'ending' | 'finished'

MatchState = {
    WAITING  = 'waiting',
    STARTED  = 'started',
    ENDING   = 'ending',
    FINISHED = 'finished',
}

---@alias RoundPhase 'freeze' | 'fighting' | 'result'

RoundPhase = {
    FREEZE   = 'freeze',
    FIGHTING = 'fighting',
    RESULT   = 'result',
}
