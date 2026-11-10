defmodule Cliente do

  defmodule Usuario do
    defstruct [:nombre, :nodo]
  end

  def iniciar do
    Process.register(self(), :servicio_respuesta)

    #Crear el usuario
    usuario = %Usuario{nombre: "Estudiante UQ", nodo: node()}

    #Intentar conexión
    case Node.connect(:"servidor@127.0.0.1") do # Ajusta el host si es necesario
      true ->
        IO.puts("Conectado al servidor exitosamente.")
        enviar_solicitudes(usuario)
        recibir_respuestas()

      _ ->
        IO.puts("Error: No se pudo conectar al nodo servidor.")
    end
  end

  defp enviar_solicitudes(usuario) do
    # El destino en el servidor es :servicio_sismos en el nodo remoto
    destino_servidor = {:servicio_sismos, :"servidor@127.0.0.1"}

    # El destino de respuesta es nuestro proceso :servicio_respuesta en nuestro nodo
    mi_destino = {:servicio_respuesta, usuario.nodo}

    solicitudes = [
      {:reporte_ciudad, "C01"}, # Ciudad con movimientos
      {:reporte_ciudad, "C03"}, # Ciudad sin movimientos
      {:reporte_ciudad, "C99"}, # Ciudad inexistente
      :reporte_general,         # Reporte general
      :fin                      # Fin
    ]

    # Enviamos todas las solicitudes en orden
    Enum.each(solicitudes, fn solicitud ->
      send(destino_servidor, {mi_destino, solicitud})
    end)
  end

  # Recursividad explícita para recibir respuestas
  defp recibir_respuestas do
    receive do
      :fin ->
        IO.puts("\n--- Fin de la comunicación ---")
        # Aquí termina el cliente

      respuesta ->
        IO.puts("\n--- Respuesta del Servidor ---")
        IO.puts(respuesta)
        recibir_respuestas() #  esperando el siguiente
    end
  end
end

Cliente.main()
