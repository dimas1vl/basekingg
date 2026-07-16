Config = Config or {}

gSquadsKind = {
    SOLO = {size = 1},
    DUO = {size = 2},
    TRIO = {size = 3},
    SQUAD = {size = 4},
    PENTA = {size = 5},
    FULL = {size = 10},
}

Config.Modes = {
    ['Battle Royale'] = {
        name = 'Battle Royale',
        description = 'Battle Royale',
        isNew = true,
        sub_modes = {
            ["Casual"] = {
                requiredSquads = 3,
                maxPlayers = 60,
                squads = {
                    solo = gSquadsKind.SOLO,
                    duo = gSquadsKind.DUO,
                },
            },
            ["Casual SQUAD"] = {
                requiredSquads = 3,
                maxPlayers = 60,
                squads = {
                    squad = gSquadsKind.SQUAD,
                },
            },
            ["Competitivo"] = {
                requiredSquads = 10,
                maxPlayers = 60,
                squads = {
                    squad = gSquadsKind.SQUAD,
                },
            },
            ["Classificatória"] = {
                requiredSquads = 10,
                maxPlayers = 60,
                squads = {
                    squad = gSquadsKind.SQUAD,
                },
                is_ranked = true,
            },
            ["Premium SQUAD"] = {
                requiredSquads = 10,
                maxPlayers = 60,
                squads = {
                    squad = gSquadsKind.SQUAD,
                },
                is_premium = true,
            },
        }
    },
    ['Treinamento'] = {
        name = 'Treinamento',
        description = 'Modos de treino',
        sub_modes = {
            ['Mata-Mata Fuzil'] = {
                requiredSquads = 1,
                squads = {
                    solo = gSquadsKind.SOLO,
                },
            },
            ['Mata-Mata Pistola'] = {
                requiredSquads = 1,
                squads = {
                    solo = gSquadsKind.SOLO,
                },
            },
            ['Rolamento com Bots + Tracking'] = {
                requiredSquads = 1,
                squads = {
                    solo = gSquadsKind.SOLO,
                },
            },
            ['Drive-Bye'] = {
                requiredSquads = 1,
                squads = {
                    solo = gSquadsKind.SOLO,
                },
            },
            ['Laboratorio'] = {
                requiredSquads = 1,
                squads = {
                    solo = gSquadsKind.SOLO,
                },
            },
        },
    },
}