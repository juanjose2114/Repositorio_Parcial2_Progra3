cd punto-1 && elixir reporte_local.exs
cd punto-2/nodo-servidor && elixir cookie.exs  # genera la misma cookie en ambos nodos
cd punto-2/nodo-servidor && elixir --sname servidor --cookie "$(cat cookie)" servidor.exs
cd punto-2/nodo-cliente && elixir --sname cliente --cookie "$(cat cookie)" cliente.exs  # C01, C03, C99; repetir este comando
