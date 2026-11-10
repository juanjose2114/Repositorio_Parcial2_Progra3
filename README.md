# Parcial 2 - Programación 3
**Universidad del Quindío - Observatorio Sismológico**

Este repositorio contiene la solución completa para el Parcial 2, dividida en dos puntos independientes. 

# Estructura del repositorio

Asegúrate de que la estructura de tu proyecto coincida con la siguiente:

```text
parcial-2-elixir/
├── README.md
├── Parcial 2 Programacion 3 20206-2.pdf
├── punto-1/
│   ├── reporte_local.exs
│   ├── sismos.exs
│   ├── util.ex
│   └── resources/
│       ├── ciudades.txt
│       ├── movimientos.txt
│       └── reporte_sismos.txt
└── punto-2/
    ├── nodo-cliente/
    │   ├── cliente.exs
    │   ├── util.ex
    │   └── cookie
    └── nodo-servidor/
        ├── servidor.exs
        ├── sismos.exs (copia de la lógica del punto 1)
        ├── util.ex
        ├── cookie
        └── resources/
            ├── ciudades.txt
            └── movimientos.txt

# Ejecucion punto 1

cd punto-1
elixir reporte_local.exs
el programa leera los archivos ciudades y movimientos
imprimira en consola generara y sobreescribira el archiov reporte_sismos.txt segun corresponda (si la lectura falla, mostrara error, no sobreescribira y mantendra el)


# Ejecucion punto 2

conectando: 
Terminal 1
cd punto-2/nodo-servidor
elixir --name servidor@127.0.0.1 --cookie micookie servidor.exs

Terminal 2
cd punto-2/nodo-cliente
elixir --name cliente@127.0.0.1 --cookie micookie cliente.exs
