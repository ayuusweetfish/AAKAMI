local buffs = {

penetrate = { 
    icon = 'quq10',
    name = 'Penetrate',
    desc = 'Enable your bullets to go through enemies',
    memory =  { 1, 2, 2 },
    sellrate = 20,
    upgrade = { 30, 40 },
    args = { 1, 2, 3 }
    -- arg: number of enemies to penetrate
},

stockpile = {
    icon = 'quq10',
    name = 'Stockpile',
    desc = 'Charge your bullets to increase damage',
    memory = { 1, 1, 2, 2 },
    sellrate = 30,
    upgrade = { 30, 40, 50 },
    args = { 1, 1.1, 1.2, 1.3 }
    -- arg: inflicted damage
},

-- TODO
--[[
energyfield = {
    prereq = 'stockpile',
    icon = 'quq10',
    memory = { 2 },
    sellrate = 40,
    upgrade = {},
    args = { 1 }
    -- arg: none
},
]]

--[[
rebound = {
    icon = 'quq10',
    memory = { 1 },
    sellrate = 30,
    upgrade = {},
    args = { 1 }
    -- arg: none
},
]]

dodge = {
    icon = 'quq10',
    name = 'Dodge',
    desc = 'Gain 10% chance to avoid bullet damage',
    memory = { 2, 2, 3 },
    sellrate = 40,
    upgrade = { 40, 50 },
    args = { 0.1, 0.12, 0.15 }
    -- arg: probability
},

rstarve = {
    icon = 'quq10',
    name = 'Red Starve',
    desc = 'Gain 50% more energy from red bullets',
    memory = { 2 },
    sellrate = 0,
    updade = {},
    args = { 1.5 }
    -- arg: multiplier of energy
},

bstarve = {
    icon = 'quq10',
    name = 'Blue Starve',
    desc = 'Gain 50% more energy from blue bullets',
    memory = { 2 },
    sellrate = 0,
    updade = {},
    args = { 1.5 }
    -- arg: multiplier of energy
},

incise = {
    icon = 'quq10',
    name = 'Incise',
    desc = 'Deal 50% more damage to enemies far away',
    memory = { 2 },
    sellrate = 0,
    updade = {},
    args = { 1.5 }
    -- arg: inflicted damage
},

fork = {
    icon = 'quq10',
    name = 'Fork',
    desc = 'Shoot 3 bullets in one shot',
    memory = { 2 },
    sellrate = 0,
    updade = {},
    args = { 1 }
    -- arg: none
},

magazine = {
    icon = 'quq10',
    name = 'Magazine',
    desc = 'Increase maximum energy by 50%',
    memory = { 2 },
    sellrate = 0,
    updade = {},
    args = { 50 }
    -- arg: additional energy
},

--[[
cannon = {
    icon = 'quq10',
    memory = { 2 },
    sellrate = 0,
    updade = {},
    args = { 1 }
    -- arg: range or damage or both?
},
]]

rage = {
    icon = 'quq10',
    name = 'Rage',
    desc = 'Double the damage of the first bullet after slaying each enemy',
    memory = { 2 },
    sellrate = 0,
    updade = {},
    args = { 1 }
    -- arg: sustain or damage or both?
},

machgun = {
    icon = 'quq10',
    name = 'Machine Gun',
    desc = 'gkd',
    memory = { 2 },
    sellrate = 0,
    updade = {},
    args = { 10 }
    -- arg: bullet interval
},

}

return buffs
