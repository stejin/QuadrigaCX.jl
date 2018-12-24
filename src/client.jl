using MbedTLS
using JSON
using Requests
import Requests: URI

type QuadrigaCXRestClient
  Config::Dict
  Debug::Bool

  QuadrigaCXRestClient() = new(load_config(), false)
  QuadrigaCXRestClient(configDict, debug) = new(configDict, debug)
end

function load_config()
  configFile = "qcx.config"
  if isfile(configFile)
    return JSON.parsefile(configFile)
  end
  return nothing
end

to_hexstring(arr::Array{UInt8,1}) = join([hex(i, 2) for i in arr])

function get_headers(client)
  headers = Dict("Content-Type" => "application/json")
end

function get_auth(client)
  key = client.Config["key"]
  clientId = client.Config["client"]
  secret = client.Config["secret"]
  nonce = Dates.value(now())
  msg = string(nonce, clientId, key)
  signature = digest(MD_SHA256, msg, secret)
  Dict("key" => client.Config["key"],
       "nonce" => nonce,
       "signature" => to_hexstring(signature))
end

function qcx_get(client, url)
  resp = Requests.get(url; headers = get_headers(client))
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

function qcx_post(client, url, data)
  resp = Requests.post(url; headers = get_headers(client), data = JSON.json(merge(get_auth(client), data)))
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
      error("Error parsing response to request with url: $url, data: $data - $resp")
    end
  end
end

function qcx_post2(client, url, data)
  resp = Requests.post(url; headers = get_headers(client), data = JSON.json(merge(get_auth(client), data)))
  if resp.status != 200
    error("$(resp.status): Error executing POST request with url: $url, data: $data - $resp")
  else
    try
      parsedresp = Requests.readstring(resp)
      parsedresp
    catch e
      error("Error parsing response to request with url: $url, data: $data - $resp")
    end
  end
end

get_balances(client) = qcx_post(client, "https://api.quadrigacx.com/v2/balance", Dict())
add_buy_order(client, amount, price, book) = qcx_post(client, "https://api.quadrigacx.com/v2/buy", Dict("amount" => amount, "price" => price, "book" => book))
add_sell_order(client, amount, price, book) = qcx_post(client, "https://api.quadrigacx.com/v2/sell", Dict("amount" => amount, "price" => price, "book" => book))
get_order(client, reference) =  qcx_post2(client, "https://api.quadrigacx.com/v2/lookup_order", Dict("id" => reference))
