
bhk_main.node_colors = {
    black     ={main="#333344",alt="#555566",outline="#555566",highlight="#444455",lowlight="#111122",raw="#5f5f64",trim="#aaaaaa",trim_low="#222222"},
    dark_grey ={main="#555566",alt="#aa9977",outline="#777788",highlight="#666677",lowlight="#444455",raw="#77777e",trim="#dddddd",trim_low="#333333"},
    grey      ={main="#888899",alt="#ffffff",outline="#9999aa",highlight="#9999aa",lowlight="#666688",raw="#838397",trim="#ffffff",trim_low="#444455"},
    light_grey={main="#aaaabb",alt="#ffffff",outline="#ccccdd",highlight="#bbbbcc",lowlight="#8888aa",raw="#9b9ba4",trim="#ffffff",trim_low="#555566"},
    white     ={main="#eeeeee",alt="#9999aa",outline="#ffffff",highlight="#ffffff",lowlight="#ddddee",raw="#e7e3de",trim="#cccccc",trim_low="#888888"},
    red       ={main="#b6333c",alt="#ffffff",outline="#cc8c7e",highlight="#c34b4c",lowlight="#c35350",raw="#aaa6a1",trim="#d4c7ac",trim_low="#782b4c"},
    -- dark_red  ={main="#641d2b",alt="#ffffff",outline="#a76553",highlight="#742d3b",lowlight="#54171b",raw="#6d6d73",trim="#b7a189",trim_low="#3d2b32"},
    -- orange    ={main="#bb8855",alt="#777788",outline="#cfab88",highlight="#cc9966",lowlight="#aa7755",raw="#b8aaa5",trim="#ffffff",trim_low="#945444"},
    rust      ={main="#756052",alt="#ffffff",outline="#877263",highlight="#877767",lowlight="#655450",raw="#73706d",trim="#aaaaaa",trim_low="#4a4240"},
    green     ={main="#4d7953",alt="#ffffff",outline="#8c8b7d",highlight="#838962",lowlight="#3c6946",raw="#77777e",trim="#cccccc",trim_low="#41534d"},
    blue      ={main="#447788",alt="#ffffff",outline="#799598",highlight="#558899",lowlight="#336677",raw="#a6a49f",trim="#ffffff",trim_low="#4c5356"},
    yellow    ={main="#c5b794",alt="#d9d8c4",outline="#ddddcc",highlight="#d5c7a4",lowlight="#b5a784",raw="#a6a49f",trim="#eeeeee",trim_low="#797773"},
    gold      ={main="#f0df81",alt="#d9d8c4",outline="#f3edc8",highlight="#d5c7a4",lowlight="#b5a784",raw="#aaa6a1",trim="#ffffff",trim_low="#888888"},
}

local c = bhk_main.node_colors

for k, v in pairs(c) do
    v.name = k
end

-- sorted loosely by luminence
bhk_main.node_colors_list = {
    c.white,
    c.light_grey,
    c.grey,
    c.gold,
    c.yellow,
    c.blue,
    c.green,
    -- c.orange,
    c.red,
    c.rust,
    -- c.dark_red,
    c.dark_grey,
    c.black,
}
