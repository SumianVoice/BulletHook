
## Multiple Finite State Machine
This allows you to have multiple states active at one time, while also allowing for typical finite state machine behaviors, like going from one state to the next and the next etc.

Here's how you use it. There are two ways; you could put it on an entity, or you could insert it into a plain table. Either way you'll want something like this.

## For entities
```lua
minetest.register_entity("my_mod:mob", {
    on_step = function(self, dtime, moveresult)
        MFSM.on_step(self, dtime) -- this and _MFSM_states is all you need
        if not self._init then
            self._init = true
            -- can't self:set_state because we can't `setmetatable` on entities, so we just do it oldschool
            MFSM.set_state(self, "idle", true, false)
        end
    end,
    _MFSM_states = {
        {
            name = "idle",
            on_step = function(self, dtime, meta)
            end,
            on_start = function(self, meta)
            end,
            on_end = function(self, meta)
            end,
            protected = true,
        },
        {
            name = "follow",
            [...]
        },
    },
})
```

## For any `table`
```lua
local my_statemachine = MFSM.new({
    _MFSM_states = {
        {
            name = "idle",
            on_step = function(self, dtime, meta)
            end,
            on_start = function(self, meta)
            end,
            on_end = function(self, meta)
            end,
            protected = true,
        },
        {
            name = "follow",
            [...]
        },
    },
})
-- if you want it to run all the time
MFSM.enable_globalstep(my_statemachine)
MFSM.set_state(my_statemachine, "idle", true, false)
```

## Things you need
`_MFSM_states` --> `table` list of all states, with their names and methods.

`[state].protected` --> `boolean` for whether to protect this so it doesn't get stopped by `exclusive` set_state calls.

The rest is up to you.

## Functions
All of these can also be `self:method()` or `my_statemachine:method()` instead of `MFSM.method(my_statemachine)`, so you can call them from within the statemachine itself.

To set states:
```lua
MFSM.set_state(self, state_name, active, exclusive)
MFSM.set_state(self, states, exclusive)
```
Example:
```lua
-- set to idle, but don't stop other states
MFSM.set_state(my_statemachine, "idle", true, false)
-- set to idle, and disable roam state, don't stop any other states
MFSM.set_states(my_statemachine, {
    idle = true,
    roam = false,
}, false)
```


Start tracking it so that `on_step` happens automatically.
```lua
MFSM.enable_globalstep(my_statemachine)
```
Stop tracking it.
```lua
MFSM.disable_globalstep(my_statemachine)
```

All methods. These are all `self:method()`-able.
```lua
MFSM.init_states(self)
MFSM.get_state_meta(self, state_name)
MFSM.do_state(self, state_name, functype, ...)
MFSM.set_state(self, state_name, active, exclusive)
MFSM.set_states(self, states, exclusive)
MFSM.on_step(self, dtime)
MFSM.reset_all_states(self, exclude_list)
MFSM.enable_globalstep(self)
MFSM.disable_globalstep(self)
```

In addition, the API will try to call these functions on your table or entity when changing states, so you can use them for callbacks.
```lua
_MFSM_on_any_state_start(self, state_name, meta)
_MFSM_on_any_state_end(self, state_name, meta)
```


With comments explaining stuff:
```lua
-- the host table you're going to put the states in
local my_table = {
    -- this is the name it expects; it must have this field or nothing will happen
    _MFSM_states = {}
}
-- table insert is clean but you can just dump them in the {} and be done with it too (like above)
-- on_step for each state is called IN ORDER that it exists within this list, so the order matters here
table.insert(my_table._MFSM_states, {
    name = "start", -- must be unique
    -- meta is a table you can store arbitrary data in, and it is unique to this state
    -- when the state ends, the meta gets destroyed
    on_step = function(self, dtime, meta)
        if meta.state_time > 10 then
            -- state_name, value, exclusive : whether to end other states that aren't `protected`
            self:set_state("end", true, false)
        end
    end,
    -- called once whn the state starts
    on_start = function(self, meta)
        core.log("started")
    end,
    -- called once when the state stops
    on_end = function(self, meta)
    end,
    -- will not be ended when set_state is used with exclusive = true
    protected = true,
})
-- another state, this one runs after the first one
table.insert(my_table._MFSM_states, {
    name = "end",
    on_step = function(self, dtime, meta)
    end,
    on_start = function(self, meta)
        core.log("got to end")
    end,
    on_end = function(self, meta)
    end,
    protected = false,
})

-- initialises it so it is using all the mfsm methods
my_table = MFSM.new(my_table)
-- the system will automatically call on_step for this now
-- don't use for entities obviously, since it would call twice per step
my_table:enable_globalstep()
```