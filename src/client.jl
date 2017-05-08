using MbedTLS
using JSON
using Requests
import Requests: URI

type QuadrigaCXHandler
  Config::Dict
  Debug::Bool

  QuadrigaCXHandler() = new(load_config(), false)
  QuadrigaCXHandler(configDict, debug) = new(configDict, debug)
end

function load_config()
  configFile = "qcx.config"
  if isfile(configFile)
    return JSON.parsefile(configFile)
  end
  return nothing
end

to_hexstring(arr::Array{UInt8,1}) = join([hex(i, 2) for i in arr])

function get_headers(handler)
  headers = Dict("Content-Type" => "application/json")
end

function get_auth(handler)
  key = handler.Config["key"]
  client = handler.Config["client"]
  secret = handler.Config["secret"]
  nonce = Int(now())
  msg = string(nonce, client, key)
  signature = digest(MD_SHA256, msg, secret)
  Dict("key" => handler.Config["key"],
       "nonce" => nonce,
       "signature" => to_hexstring(signature))
end

function qcx_get(handler, url)
  resp = Requests.get(url; headers = get_headers(handler))
  if resp.status != 200
    error("$(resp.status): Error executing GET request with url: $url, resp: $resp")
  else
    try
      parsedresp = Requests.json(resp)
      parsedresp
    catch e
      error("Error parsing response to GET request with url: $url, resp: $resp")
    end
  end
end

function qcx_post(handler, url, data)
  resp = Requests.post(url; headers = get_headers(handler), data = JSON.json(merge(get_auth(handler), data)))
  if resp.status != 200
    error("$(resp.status): Error executing POST request with url: $url, data: $data - $resp")
  else
    try
      parsedresp = Requests.json(resp)
      if "error" in keys(parsedresp)
        println("Error parsing response to request with url: $url, data: $data - $(parsedresp["error"])")
      end
      parsedresp
    catch e
      error("Error parsing response to request with url: $url, data: $data - $resp - $parsedresp")
    end
  end
end

get_balances(handler) = qcx_post(handler, "https://api.quadrigacx.com/v2/balance", Dict())
add_buy_order(handler, amount, price, book) = qcx_post(handler, "https://api.quadrigacx.com/v2/buy", Dict("amount" => amount, "price" => price, "book" => book))
add_sell_order(handler, amount, price, book) = qcx_post(handler, "https://api.quadrigacx.com/v2/sell", Dict("amount" => amount, "price" => price, "book" => book))
