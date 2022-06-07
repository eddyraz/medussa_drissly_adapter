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
        y el segundo parametro es una tupla de 6 valores en la que se setean los 
        valores c  orrespondientes en dependencia del tipo de operacion 
        y los demas se dejan con el valor nil. los datos de autenticacion 
        se ponen por defecto en el body cargados desde la configuracion.
                           
        los valores de la tupla son {
                                     numero_telefonico,
                                     tipo_de_servicio_o_producto,
                                     cantidad_a_recargar,
                                     texto_adicional,
                                     numero_referencia,
                                     folio  
                                     } 
                           
        Nota: El folio solo se necesita para la consulta de una transaccion previa.
                             
        Ejemplo para el catalogo de productos solo necesitamos el tipo de operacion[19~], y nada mas, por lo que quedaria asi.
        Medusa.DrisslyAdapter.make_request("catalogo_servicios",{nil,nil,nil,nil,nil,nil})
                           
        Para la recarga necesitamos el tipo de operacion, el numero   
                           


  """
  import Record
  require EEx
  use Timex
  import Logger
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

    phone_num = options[:num]
    tos = options[:tos]
    spa = options[:spa]
    addition_text = options[:add_text]
    ref = options[:ref]
    folio = options[:folio]

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
    |> parse_response()
  end

  defp get_url(class) do
    @config[:endpoints][:base] <> @config[:endpoints][String.to_atom(class)]
  end

  def get_user_name() do
    @config[:headers][:login][:email]
  end

  def get_password() do
    @config[:headers][:login][:password]
  end

  defp send_request(action, url, phone_number, tos, spa, ad, ref, fol) do
    payment_id = UUID.uuid4()

    Logger.info("ID de Operacion #{payment_id} Drissly URL: #{url} ")

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

    
    {:ok, response} = Tesla.post(url, body, headers: get_headers())

    # server_response_body = response.body |> Jason.encode
    # Logger.info("Drissly Response: #{server_response_body}")

    #    parse_response(payment_id, response)
  end

  # top = Type of service, calling_station = phone_number
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

      "login" ->
        ''	
	
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
        ''

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

  def get_time() do
    # Timex.format!(Timex.now("America/Mexico_City"), "%Y-%m-%d %H:%M:%S.%L", :strftime)
    :hello
  end

  defp parse_response(raw_response) do
     response = Jaxon.decode(elem(raw_response,1).body) |> elem(1)

#     status_code = get_status_code(response)
#     message = get_message(response)
#     error_message = get_error(response)

#        case status_code do
#                400 ->
#                Logger.error("#{ops_id}, #{get_time()} Drissly Response: #{response.body}")
 #               {:error, "Drissly: Bad Request"}
#              401 ->
#                Logger.error("#{get_time()} Drissly Response: #{response.body}")
#              403 ->
#                log :error, ops_id, "#{get_time()} Drissly Response: #{response.body}"
#                {:error, "Drissly: Access Forbidden"}
#              500 ->
#                log :error, ops_id, "#{get_time()} Drissly Response: #{response.body}"
#                {:error, "Drissly: Internal Server Error"}
    
#              502 ->
#     	    Logger.error("#{ops_id} #{get_time()} Drissly Response: #{response.body} error, #{error_me#ssage}")
#              _ ->
 #           Logger.error("#{error_message}, #{ops_id}, #{get_time()} Drissly Response: #{response.body}")
                
#    end
end 
	
  

  defp get_headers() do
    [
      "User-Agent": "Miio",
      "Content-Type": @config[:headers][:auth][:content_type],
      Authorization: "Bearer " <> @config[:headers][:auth][:token]
    ]
    end
    

  defp get_bearer_token(:user_cred) do
    user_token = :user_cred
  end

  def get_attemps(class) do
    case class do
      "Servicios" ->
        @attempts_services_timeout

      "Recarga tae" ->
        @attempts_tae

      _ ->
        0
    end
  end

  def get_status_code(res) do
    status_code = res["code"]
  end

  def get_message(res) do
    error_message = res["message"]
  end

  def get_error(res) do
    error_message = res["error"]
  end
end

# Catalogo de productos
# Medusa.DrisslyAdapter.make_request("catalogo_productos",[])

# Catalogo de Servicios
# Medusa.DrisslyAdapter.make_request("catalogo_servicios",[])

# Recarga de tae
# Medusa.DrisslyAdapter.make_request("recarga",[num: "5512345678",tos: 78,spa: 100])

# Pago de servicio
# Medusa.DrisslyAdapter.make_request("pago_servicio",[num: "5512345678",tos: 98,spa: 100,add_text: "TEST",ref: 010101010101])

# Consulta transaccion
# Medusa.DrisslyAdapter.make_request("consulta_transaccion",[folio: 9064])
