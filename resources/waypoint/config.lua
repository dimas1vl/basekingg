local config = {}

-------------------------------------------------
-- Map Waypoint Sync
-------------------------------------------------
-- When enabled, a waypoint marker will be created at the player's map waypoint
config.syncToWayPoint = true

-- Settings for the auto-created map waypoint marker
config.mapWaypoint = {
    type = 'checkpoint',
    label = 'WAYPOINT',
    color = '#f500fc',
    size = 1.0,
    drawDistance = 1000.0,
}

-------------------------------------------------
-- Default Waypoint Settings
-------------------------------------------------
-- These values are used when not specified in waypoint creation
config.defaults = {
    -- Rendering
    drawDistance = 500.0, -- Maximum distance to render the waypoint
    fadeDistance = 400.0, -- Distance at which waypoint starts fading
    size = 1.0,           -- Base size multiplier

    -- Height settings (for checkpoint type)
    minHeight = 0.5,      -- Minimum marker height
    maxHeight = 8000.0,     -- Maximum marker height
    groundZOffset = -2.0, -- Offset from coords.z for ground position

    -- Appearance
    color = '#f5a623',      -- Default marker color (hex)
    label = 'CHECKPOINT',   -- Default label text
    displayDistance = true, -- Show distance on marker by default
}

-------------------------------------------------
-- Interaction Marker Settings (loot prompt)
-------------------------------------------------
-- The DUI texture is 512x1024 (portrait). To avoid distortion the world quad
-- must share the same aspect (0.5), so worldHeight = worldWidth * 2. The modal
-- HTML occupies the bottom slice of the texture; the rest is transparent.
config.interaction = {
    drawDistance = 8.0,     -- Only render when within this distance of the item
    worldWidth = 0.55,      -- World-space width of the sprite quad (meters)
    worldHeight = 1.1,      -- World-space height of the sprite quad (meters, = worldWidth * 2)
    zOffset = 0.65,         -- Height above the item coord where the modal bottom sits
    drawLine = false,       -- Interaction marker has no vertical line/arrow
}

-------------------------------------------------
-- DUI Settings
-------------------------------------------------
config.dui = {
    width = 512,   -- DUI texture width in pixels
    height = 1024, -- DUI texture height in pixels
}

-------------------------------------------------
-- Rendering Settings
-------------------------------------------------
config.rendering = {
    -- Main loop update interval (ms) - how often to check which waypoints should render
    updateInterval = 100,

    -- Distance text update interval (ms) - how often to update distance text on waypoints. this will significantly reduce performance if lowered
    distanceUpdateInterval = 100,

    -- Perspective scaling
    perspectiveDivisor = 20.0, -- Divides camera distance to calculate perspective scale

    -- Checkpoint type scaling
    checkpointBaseMultiplier = 4.0, -- Multiplier for checkpoint base size
    checkpointMinScale = 0.1,       -- Minimum perspective scale for checkpoints
    checkpointAspectRatio = 2.0,    -- Height to width ratio for checkpoint quads
    checkpointLineHeightRatio = 0.62, -- Fraction of the original 3D marker height used by the world line
    checkpointPanelWidthRatio = 1.0, -- Width ratio applied to the projected 2D panel
    checkpointPanelHeightRatio = 0.75, -- Height ratio applied to the projected 2D panel

    -- Small type scaling
    smallMinScale = 1.0,    -- Minimum perspective scale for small markers
    smallAspectRatio = 2.0, -- Height to width ratio for small marker quads
    smallLineHeightRatio = 0.5, -- Fraction of the original 3D marker height used by the world line
    smallPanelWidthRatio = 1.0, -- Width ratio applied to the projected 2D panel
    smallPanelHeightRatio = 0.9, -- Height ratio applied to the projected 2D panel

    -- Hybrid line styling
    worldLineThicknessRatio = 0.027, -- Thickness ratio of the 3D line relative to marker width
}

-------------------------------------------------
-- Server Settings
-------------------------------------------------
config.server = {
    -- Cleanup interval for checking disconnected players (ms)
    cleanupInterval = 60000,

    -- Enable version checking on server start
    versionCheckEnabled = true,
}

return config
