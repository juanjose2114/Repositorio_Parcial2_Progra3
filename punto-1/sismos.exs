defmodule Sismos do

  #structs como submomdulos para organizar
  defmodule Ciudad do
    defstruct [:id, :nombre, :habitantes]
  end

  defmodule Movimientos do
    defstruct [:codigo, :id_ciudad, :hora_inicio, :hora_final, :magnitud, :profundidad]
  end


  #lectura concurrente con coordinador
  def leer(ruta_ciudades, ruta_sismos) do

    coordinador = self()

    #refenercia unica con make_ref para evitar confuciones
    ref = make_ref()

    #spawn a leer archivo para ciudades y sismos
    spawn(fn ->
      send(coordinador, {ref, :ciudades, leer(ruta_ciudades)})
    end)

    spawn(fn  ->
      send(coordinador, {ref, :movimientos, leer(ruta_sismos)})
    end)

    recibir(ref, %{})

  end

  #recibe en cualquier orden, termina cuando tiene ambas
  defp recibir(_, acc) when map_size(acc) == 2, do: acc

  defp recibir(ref, acc) do
    #^rev exige exactamente el mismo para evitar errores
    #Map.put añade/remplaza la clave del mapa
    receive do
      {^ref, :ciudades, resultado} ->
        recibir(ref, Map.put(acc, :ciudades, resultado))

      {^ref, :movimientos, resultado} ->
        recibir(ref, Map.put(acc, :movimientos, resultado))
    end
  end

  defp leer (ruta) do
    case File.read(ruta) do
       {:ok, contenido} -> {:ok, String.split(contenido, "\n")}
       #hace split para cada linea

       {:error, motivo} -> {:error, motivo}

    end
  end

  #-----------------------------------------------------------------

  defp parsear([], acc, rechazados, _f) do
    #con una lista vacia, reorganizamos acc, _f no se usa en este caso pero sirbe para el pathern machine
    {Enum.reverse(acc), rechazados}

  end

  defp parsear([linea | resto], acc, rechazados, f) do
    #limpiamos
    linea = String.trim(linea)

    cond do
      linea == "" ->
        parsear(resto, acc, rechazados, f)
        #cond verifica que la linea no este vacia para poder continuar
        #si es "" se lo salta y continua con el resto
        #la ia me ayudo con este para tolerar las lineas vacias

      true ->
        case f.(linea) do
          {:ok, valor} ->
            parsear(resto, [valor | acc], rechazados, f)
            #continua parseando si no hay fallo, [valor | acc] agrega el retorno de f al acumulado

          :error ->
            parsear(resto, acc, rechazados + 1, f)
            #en caso de fallar, no agrega a acc, continua con el resto y suma un rechazo
        end

    end
  end

  defp parsear_ciudades(lineas) do
    parsear(lineas, [], 0, &parsear_ciudad/1)
    #lineas del archivo, acumulador vacio, contador de rechazados, puntero a funcion (una sola funcion de recorrido para dos validaciones)
    #{lista ciudades, rechazados}
  end

  defp parsear_ciudad(linea) do

    #string split separa la linea cada que encuentra un @ y luego lo verificamos
    #id@nombre@habitantes -> [id, nombre, habitantes]
    case String.split(linea, "@") do
      [id, nombre, habitantes] when id != "" and nombre != "" and habitantes != "" ->
        #verifica que no hallan espacios vacios y solo hallan 3 espacios

        case Integuer.parse(habitantes) do
          {n, ""} when n > 0 ->
            {:ok, %Ciudad{id: id, nombre: nombre, habitantes: n}}
            #verifica entonces que los habitantes sean validos, numeros matores a 0
            #aplica luego el struct

          _ ->
            :error
            #si se le envia algo como "123a" -> _ falla y no lo hacepta
        end
    end
  end

  defp parsear_movimientos(lineas, ids_validos) do
    #reibe ids validos de ciudades como MapSet
    parsear(lineas, [], 0, fn linea ->
      case parsear_movimiento(linea) do
        {:ok, mov} ->
          if MapSet.member?(ids_validos, mov.id_ciudad) do
            #verifica que la ciudad de la linea sea valida mediante el id
            {:ok, mov}

          else
            #no hacepta ciudad con id no registrado y lo cuenta como rechazado
            :error

          end
        :error ->
          #error en parseo, sigue en error
          :error
      end
      #se cambia la funcion puntero por una funcion anonima para operar los ids validos y contar los rechazados
      #la ia tambien me ayudo con este porque es diferente el como se aplica para ciudades y movimientos, aplicando una solucion personalizada para movimientos
      #linea de archivo, acumulador vacio, contador de rechazados
    end)


  end

  defp parsear_movimiento(linea) do

    #string split separa la linea cada que encuentra un @ y luego lo verificamos .viva el ctrl c y ctrl v
    #codigo@id_ciudad@hi@hf@magnitud@profundidad -> [codigo, id_ciudad, hi, hf, magnitud, profundidad]
    case String.split(linea, "@") do
      [codigo, id_ciudad, hi, hf, magnitud, profundidad] when codigo != "" and id_ciudad != "" and hi != "" and hf != "" and magnitud != "" and profundidad != "" ->
        #verifica los 6 espacios y que no esten vacios
        with {:ok, _} <- hora_valida(hi),
             {:ok, _} <- hora_valida(hf), #verifica que hi y hf esten :ok, el valor no lo evalua
             {mag,  ""} when is_float(mag) or is_integer(mag) <- parse_float(magnitud), #descarta texto de magnitud
             {prof, ""} when prof >= 0 <- parse_float(profundidad) do #descarta texto de profundidad y verifica que sea numero positivo

              #una vez verifica las horas, magnitud y profundidad con valores leibles retorna:
              {:ok, %Sismos.Movimientos{codigo: codigo, id_ciudad: id_ciudad, hora_inicio: hi, hora_final: hf, magnitud: mag / 1, profundidad: prof / 1}}
              #con mag / 1 y prof / 1 fuerza el tipo float    4 -> 4.0
              #[:codigo, :id_ciudad, :hora_inicio, :hora_final, :magnitud, :profundidad]

            else
              _-> :error
            end

    _ ->
      :error  #en caso de que split no retorne lo que se desea, retorna :error

        #visual sc me recomendo el uso de este with, con ayuda de otra ia pude entender que, por que y como funciona with
        #es un conjunto de patern matches que evita fallos
    end

  end

  #-----------------------------------------------------------------

  defp hora_valida(hora) do

    #una vez dividido en lineas ("\n") y luego en variables ("@"), se transforma la hora "HH:MM:NN" en [h,m,s] para verificarla
    case String.split(hora, ":") do
      [h,m,s] ->

        with  {hh, ""} when hh in 0..23 <- Integer.parse(h),
              {mm, ""} when mm in 0..59 <- Integer.parse(m),
              {ss, ""} when ss in 0..59 <- Integer.parse(s) do

                {:ok, hora} #no interesa el formato, solo su validez
              else
                _ -> :error
              end

    _ ->
      :error
    end
    #para este caso tomamos el rango de un dia de 23h:59m:59s, siendo la 24h parte del siguiente dia
  end

  defp parse_float(s) do
    case Float.parse(s) do
      {f, ""} -> {f,""} #intenta parsear ("float") a (float, "")
      #de no poder por ser integer, continua con Integuer parse
      _ ->
        case Integer.parse(s) do
          {i, ""} -> {i/1, ""} #transforma con Integer.parse y fuerza float dividiendo en 1

          _ ->
            :error #en caso de no poder como float o integer, retorna :error
        end
    end
  end

  #-----------------------------------------------------------------

  def calcular_estadisticas(movimientos) do
    #aplicamos recursividad para pasar por todos los movimientos
    recorrer(movimientos, 0, nil, 0.0)
    #recorre los movimientos con un inicial de 0 movimientos, el maximo movimiento nil, y la suma de profundidades 0.0
    #la suma despues se usara para calcular promedio de profundidad
  end

  #caso base sin movimientos, accesible desde el primer llamado de calcular_estadisticas
  defp recorrer([], 0, nil, 0.0) do
    %{total: 0, max: nil, prom: nil}
  end


  #caso base, recorrido completo
  defp recorrer([], total, max, suma) do
    %{total: total, max: max, prom: suma / total}
    #retorna la cantidad, el maximo y el promedio (suma de profundidades/cantidad)
    #%{cantidad, maximo, promedio profundidad}
  end

  defp recorrer([movimiento | resto], total, nil, suma) do
    recorrer(resto, total + 1, movimiento, suma + movimiento.profundidad)
    #en el primer recorrido el max es nil, se toma como max el primer movimiento por el momento
  end

  #caso movimiento actual es mayor al movimiento maximo, elixir confirma primero la de arriba por lo que no hay posibilidad de fallo
  defp recorrer([movimiento | resto], total, max, suma) when movimiento.magnitud > max.magnitud do
    recorrer(resto, total + 1, movimiento, suma + movimiento.profundidad)
    #continua con la cola, suma 1 a la cantidad, cambia el maximo y suma la profundidad acumulada con la actual
  end

  defp recorrer([movimiento | resto], total, max, suma) do
    recorrer(resto, total + 1, max, suma + movimiento.profundidad)
    #continua con la cola, suma 1 a la cantidad, conserva el maximo y suma la profundidad acumulada con la actual
  end

  #-----------------------------------------------------------------

  def generar_reporte(ciudades, movimientos, rech_ciudades, rech_movimientod) do
    #construccion de la forma %{idciudad con sus movimientos[mov1, mov2], idciudad 2 ...}
    por_ciudad = agrupar(movimientos)
    cuerpo = Enum.map_join(ciudades, "\n", fn c ->
                #aplicamos a todas las ciudades la funcion
                movs = Map.get(por_ciudad, c.id, []) #trae los movimientos de la ciudad del id
                reporte_ciudad(c, movs) #genera reporte de ciudad
              end)
              #map join se supone que las separa con \n, idea de la ia y me parecio bonito y comodo dejarlo

    """
    ===REPORTE DE SISMOS ===
    #{cuerpo}

    Registros rechazados:
      Ciudades: #{rech_ciudades}
      Movimientos: #{rech_movimientod}
    """
    #mensaje heredoc que se retornara al generar reporte, el #{cuerpo} mostrara el reporte generado para cada ciudad
    #al no saber la mejor manera de generar el mensaje para retornarlo, la ia me recomendo el heredoc

  end

  #agrupacion recursiva, inicia el acumulador
  defp agrupar(movimientos) do
    agrupar(movimientos, %{})
  end

  #agota la lista y retorna unicamente el acumulado
  defp agrupar([], acc) do
    acc
  end

  #para cada movimiento, obtiene una lista, agrega el movimiento actual al acc
  defp agrupar([m | resto], acc) do
    lista = Map.get(acc, m.id_ciudad, [])
    agrupar(resto, Map.put(acc, m.id_ciudad, lista ++ [m]))
  end


  #si [] esta vacio, retorna le texto
  defp reporte_ciudad(ciudad, []), do:
  """
  #{ciudad.nombre} (#{ciudad.habitantes} habitantes)
    Sin movimientos registrados
    Total: 0 | Máx: No aplica | Prom. profundidad: No aplica
  """

  #calcula %{total, max, prom} con recurcion
  defp reporte_ciudad(c, movs) do
    est = calcular_estadisticas(movs)

    detalle = Enum.map_join(movs, "\n", fn m ->
      "    #{m.codigo} | #{m.hora_inicio}-#{m.hora_final} | mag #{m.magnitud} | prof #{m.profundidad} km"
    end)
    #mapea movs para generar cada movimiento en una linea con codigo, horas, magnitud y profundidad


    """
    #{c.nombre} (#{c.habitantes} habitantes)
    #{detalle}
      Total: #{est.total} | Máx: #{est.max.codigo} (#{est.max.magnitud}) | Prom. profundidad: #{:erlang.float_to_binary(est.prom, decimals: 2)} km
    """
    #retorno de ciuda, habitantes, y sus detalles
    #detalles con un movimiento por linea, con codigom horas magnitud y profundidad

    #luego con est llama a calcular_estadisticas y lo imprime como: total(cantidad de mov), max codigo y magnitud del mayor mov, promedio de profundidad con dos decimales (funcion erlang gracias a ia)
  end







end
