Config = Config or {}

Config.LobbyMinigames = {
    spawn = {
        coords  = vec3(-3763.03, -1596.63, 6.89),
        heading = 143.0,
    },

    npcs = {
        {
            modeId       = 'clutch',
            label        = 'Clutch',
            mode         = 'Mini Games',
            subMode      = 'Clutch',
            squadType    = 'solo',
            model        = 'a_m_y_business_03',
            coords       = vec4(-3756.42, -1606.95, 6.21, 35.9),
            interactDist = 3.0,
            promptKey    = 'E',
        },
        {
            modeId       = 'gang',
            label        = 'Gang',
            mode         = 'Mini Games',
            subMode      = 'Gang',
            squadType    = 'solo',
            model        = 'a_m_m_business_01',
            coords       = vec4(-3765.37, -1607.88, 6.21, 350.7),
            interactDist = 3.0,
            promptKey    = 'E',
        },
        {
            modeId       = 'predio',
            label        = 'Predio',
            mode         = 'Mini Games',
            subMode      = 'Predio',
            squadType    = 'solo',
            model        = 'a_m_y_business_01',
            coords       = vec4(-3751.18, -1600.77, 6.21, 70.1),
            interactDist = 3.0,
            promptKey    = 'E',
        },
        {
            modeId       = 'dominacao',
            label        = 'Dominacao',
            mode         = 'Mini Games',
            subMode      = 'Dominacao',
            squadType    = 'solo',
            model        = 'a_m_y_business_02',
            coords       = vec4(-3751.30, -1592.78, 6.21, 116.5),
            interactDist = 3.0,
            promptKey    = 'E',
        },
    },
}
