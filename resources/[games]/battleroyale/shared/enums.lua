---@alias MatchState 'waiting' | 'airplane' | 'started' | 'ending' | 'finished'

MatchState = {
    WAITING  = 'waiting',
    AIRPLANE = 'airplane',
    STARTED  = 'started',
    ENDING   = 'ending',
    FINISHED = 'finished',
}

---@alias PlayerState 'alive' | 'injured' | 'dead' | 'spectating'

PlayerState = {
    ALIVE      = 'alive',
    INJURED    = 'injured',
    DEAD       = 'dead',
    SPECTATING = 'spectating',
}
