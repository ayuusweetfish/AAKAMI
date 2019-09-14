return {

penetration = { 
    icon = 'quq10',
    memory = 1,
    sellrate = 20,
    upgrade = { 30, 40 },
    args = { 1, 2, 3 }
},

stockpile = {
    icon = 'quq11',
    memory = 1,
    sellrate = 30,
    upgrade = { 30, 40, 50 },
    args = { 1, 1.1, 1.2, 1.3 }
},

energyfield = {
    prereq = 'stockpile',
    icon = 'quq12',
    memory = 2,
    sellrate = 40,
    upgrade = {},
    args = { 1 }
},

rebound = {
    icon = 'quq13',
    memory = 1,
    sellrate = 30,
    upgrade = {},
    args = { 1 }
},

dodge = {
    icon = 'quq14',
    memory = 2,
    sellrate = 40,
    upgrade = { 40, 50 },
    args = { 0.1, 0.12, 0.15 }
},

}
