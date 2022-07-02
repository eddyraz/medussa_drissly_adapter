defmodule Medusa.DrisslyAdapter do
  @moduledoc """
        Documentation for `Medusa.DrisslyAdapter`.

        Estos son los Endpoints
        base:  "https://sandbox.drissly.com/api/v1",
        login: "/auth/login" ,
        catalogo_productos: "/get_products",
        catalogo_servicios: "/get_services",
        consulta_saldo: "/get_balance",
        recargas: "/transactions",
        pago_servicio: "/transaction_service",
        consulta_transaccion: "/consult_transaction"

        Para usar el modulo se debe hacer llamado a una funcion
        de entrada make_request/2 la cual toma dos parametros
        el primero es el tipo de operacion
        (uno por endpoint a partir de catalogo_productos)
        y el segundo parametro es una named list de hasta 6 valores en la que se escpecifican solo los
        valores correspondientes en dependencia del tipo de operacion
        . los datos de autenticacion se ponen por defecto en el body cargados desde la configuracion.

        los valores de la named list son {
                                     phone: numero_telefonico,
                                     id_product: tipo_de_servicio_o_producto,
                                     amount: cantidad_a_recargar,
                                     aditional: texto_adicional,
                                     reference: numero_referencia,
                                     folio: no_de_folio
                                     }

   
        Ejemplo para el catalogo de productos o servicios  solo necesitamos el tipo de operacion, y nada mas, por lo que quedaria asi.
        Medusa.DrisslyAdapter.make_request("catalogo_servicios",[])
      
        o
   
        Medusa.DrisslyAdapter.make_request("catalogo_productos",[])

        Para consulta de saldo
        Medusa.DrisslyAdapter.make_request("consulta_saldo",[])

        Para la recarga de tae necesitamos el tipo de operacion y el numero de telefono por loq ue quedara asi
        Medusa.DrisslyAdapter.make_request("recarga",[phone: "5512345678"])
      
        Para pago de servicio
        Medusa.DrisslyAdapter.make_request("pago_servicio",[phone: "5512365765", id_product: 218, amount: 100, aditional: "TEST", reference: "10101010101010102"])

        Para consulta de transaccion
        Medusa.DrisslyAdapter.make_request("consulta_transaccion",[folio: 1687])   
        
  """

  import Record
  require EEx
  use Timex
  require Logger
  import UUID
  use Tesla

  @drissly_timeout_tae 60
  @drissly_timeout_servicios 75
  @config Application.get_env(:medusa, :drissly)

  @doc """
      Esta funcion construye la solicitud que se le enviara a la API de Drissly                  recibiendo como parametros el tipo de operacion(),y una lista con parametros opc           ionales como el numero de telefono, el tipo de servicio, la cantidad de dinero             en caso de pago, y el numero de referencia en caso de pago
  """
  def make_request(ops, options) do
    operation_id = UUID.uuid4()

    url = get_url(ops)

    phone_num = options[:phone]
    tos = options[:id_product]

    spa = options[:amount]
    addition_text = options[:aditional]
    ref = options[:reference]
    folio = options[:folio]

    if phone_has_10_digits?(phone_num) or
         ops == "catalogo_productos" or
         ops == "consulta_saldo" or
         ops == "catalogo_servicios" or
         ops == "consulta_transaccion" do
      send_request(
        ops,
        url,
        phone_num,
        tos,
        spa,
        addition_text,
        ref,
        folio
      )
      |> parse_response(ops, url)
    else
      Logger.error("Drissly Error: Verifique el numero de telefono, debe tener 10 digitos")
    end
  end

  defp get_url(class) do
    @config[:endpoints][:base] <> @config[:endpoints][String.to_atom(class)]
  end

  defp get_user_name() do
    @config[:headers][:login][:email]
  end

  defp get_password() do
    @config[:headers][:login][:password]
  end

  defp send_request(action, url, phone_number, tos, spa, ad, ref, fol) do
    # log =
    #   _body
    #   |> String.replace(get_user_name(), "*****")
    #   |> String.replace(get_password(), "*****")

    # log(:info, payment_id, "#{get_time()} Drissly Request: #{log}")

    body =
      get_body(
        action,
        phone_number,
        tos,
        spa,
        ad,
        ref,
        fol
      )
      |> Jason.encode()
      |> elem(1)

    {:ok, response} =
      Tesla.post(url, body, headers: get_headers(), recv_timeout: get_timeout(action))
  end

  defp get_timeout(toop) do
    cond do
      toop == "recarga" ->
        @drissly_timeout_tae

      true ->
        @drissly_timeout_servicios_supl
    end
  end

  defp get_body(
         ops,
         calling_station,
         type_of_service,
         service_payment_ammount,
         additional,
         reference,
         folio
       ) do
    case ops do
      "catalogo_productos" ->
        ''

      "catalogo_servicios" ->
        ''

      "recarga" ->
        %{
          email: get_user_name(),
          password: get_password(),
          phone: calling_station,
          id_product: type_of_service
        }

      "consulta_saldo" ->
        %{email: get_user_name(), password: get_password()}

      "pago_servicio" ->
        %{
          phone: calling_station,
          id_product: type_of_service,
          ammount: service_payment_ammount,
          additional: additional,
          reference: reference
        }

      "consulta_transaccion" ->
        %{
          email: get_user_name(),
          password: get_password(),
          folio: folio
        }
    end
  end

  defp get_time() do
    # Timex.format!(Timex.now("America/Mexico_City"), "%Y-%m-%d %H:%M:%S.%L", :strftime)
    :hello
  end

  defp parse_response(raw_response, action, url) do
    payment_id = UUID.uuid4()
    initial_log(payment_id, action)
    log_de_operacion = Logger.info("ID de Operacion #{payment_id} Drissly URL: #{url} ") 

    response = Jaxon.decode(elem(raw_response, 1).body) |> elem(1)
    status_code = get_status_code(response) |> Integer.to_string()
    message = get_message(response)
    error_message = get_error(response)

    IO.inspect(response)
    
    data = process_logs(status_code,error_message,message,response)
    |> Jason.encode! |> persist_logs(payment_id,log_de_operacion)
    close_log(payment_id)
 
    
    
  end

  defp process_logs(status_cod, err_messg, messg, resp) do
    cond do
      status_cod == "200" ->
        msg = resp

      status_cod == "400" ->
        msg = Logger.error("Drissly Response: Codigo de error: #{status_cod} , #{messg}")

      Regex.match?(~r/^(40[1|3])/, status_cod) ->
        msg = Logger.error("Drissly Error: Codigo de error: #{status_cod}, #{resp}")

      Regex.match?(~r/^(50)/, status_cod) ->
        msg =
          Logger.error(
            "Drissly Error: Codigo de error: #{status_cod}, Tipo de error: #{err_messg}"
          )

      true ->
        msg = resp
    end
  end

  defp persist_logs(msg,ops_id,request_log) do
    IO.inspect(ops_id <> msg)
    
   IO.binwrite(Application.get_env(:medusa, :"#{ops_id}"), "#{request_log}\n\n #{msg}\n")
 
    
  end

  defp get_headers() do
    [
      "User-Agent": "Miio",
      "Content-Type": @config[:headers][:auth][:content_type],
      Authorization: "Bearer " <> get_bearer_token()
    ]
  end

  defp get_login_headers() do
    [
      "User-Agent": "Miio",
      "Content-Type": @config[:headers][:auth][:content_type]
    ]
  end

  
  defp get_bearer_token() do
    body =
      %{
        email: get_user_name(),
        password: get_password()
      }
      |> Jason.encode()
      |> elem(1)

    url = @config[:endpoints][:base] <> @config[:endpoints][:login]
    {:ok, response} = Tesla.post(url, body, headers: get_login_headers, recv_timeout: 75_000)

    usr_token =
      (response.body
       |> Jason.decode()
       |> elem(1))["token"]
  end

  defp get_status_code(res) do
    status_code = res["code"]
  end

  defp parse_status_code(scode) do
  end

  defp get_message(res) do
    error_message = res["message"]
  end

  defp get_error(res) do
    error_message = res["error"]
  end

  defp phone_has_10_digits?(number) do
    if number |> to_charlist |> length == 10 do
      true
    else
      false
    end
  end

  # Para la persistencia de los logs en ficheros
  defp initial_log(payment_id, class) do
    IO.inspect(@config[:project_root])
    IO.inspect("#{@config[:project_root]}/lib/logs/#{get_path(class)}/#{payment_id}.log")

    IO.inspect(get_path(class))
    {:ok, file} = File.open("logs/#{get_path(class)}/#{payment_id}.log", [:append])
    Application.put_env(:medusa, :"#{payment_id}", file, persistent: true)
  end

  defp close_log(payment_id) do
    File.close(Application.get_env(:medusa, :"#{payment_id}"))
    
  end

  defp get_path(class) do
    @config[:log_path][get_type(class)]
  end

  def get_type(class) do
    case class do
      "pago_servicio" ->
        :drissly_services

      "recarga" ->
        :drissly_tae

      _ ->
        nil
    end
  end
end

# Catalogo de productos
# Medusa.DrisslyAdapter.make_request("catalogo_productos",[])

# Catalogo de Servicios
# Medusa.DrisslyAdapter.make_request("catalogo_servicios",[])

# Recarga de tae
# Medusa.DrisslyAdapter.make_request("recarga",[phone: "5512345678", id_product: 78,amount: 100])

# Pago de servicio
# Medusa.DrisslyAdapter.make_request("pago_servicio",[phone: "5512345678",id_product: 98,amount: 100,aditional: "TEST",reference: 010101010101])

# Consulta transaccion
# Medusa.DrisslyAdapter.make_request("consulta_transaccion",[folio: 9064])
