defmodule Util do

   def mostrar_mensaje(mensaje) do
      mensaje
      |> IO.puts()
   end

   def mostrar_error(mensaje) do
      IO.puts(:standard_error, mensaje)
    end

   def mostrar_mensaje_java(mensaje) do
       System.cmd("java",["-cp",".","Mensaje", mensaje])
   end

  #pattern matching
  def ingresar(mensaje,:texto) do # atomo
    mensaje
    |> IO.gets()
    |> String.trim()
  end

  def ingresar(mensaje,:entero) do
    ingresar(mensaje,&String.to_integer/1,:entero)
  end

  def ingresar(mensaje,:real) do
    ingresar(mensaje, &String.to_float/1,:real)
  end

  def ingresar(mensaje,parser,tipo_dato) do
   try do
      mensaje
      |> ingresar( :texto)
      |> parser.()
    rescue
        ArgumentError ->
          "Error, se espera que ingrese un número #{tipo_dato}\n"
          |> mostrar_error()

          mensaje
          |> ingresar(parser,tipo_dato)
    end
  end

  def formater (valor)do
      :erlang.float_to_binary(valor,decimals: 2)
  end


end
