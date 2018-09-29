require 'net/http'
require 'uri'
require 'json'
 
# https://en.bitcoin.it/wiki/API_reference_(JSON-RPC)#Ruby 
 
DEFAULT_SERVICE_URL =  "http://bitcoin:local321@10.5.0.10:18332"

class BitcoinRPC
  def initialize(service_url = DEFAULT_SERVICE_URL)
    @uri = URI.parse(service_url)
  end
 
  def method_missing(name, *args)
    post_body = { 'method' => name, 'params' => args, 'id' => 'jsonrpc' }.to_json
    resp = JSON.parse( http_post_request(post_body) )
    raise JSONRPCError, resp['error'] if resp['error']
    resp['result']
  end
 
  def http_post_request(post_body)
    http    = Net::HTTP.new(@uri.host, @uri.port)
    request = Net::HTTP::Post.new(@uri.request_uri)
    request.basic_auth @uri.user, @uri.password
    request.content_type = 'application/json'
    request.body = post_body
    http.request(request).body
  end
 
  class JSONRPCError < RuntimeError; end
end
 
if $0 == __FILE__
   rpc = BitcoinRPC.new
   ##Generating 3 addresses
   Addr1= rpc.getnewaddress
   Pub1 = rpc.validateaddress(Addr1)
   Addr2= rpc.getnewaddress
   Pub2 = rpc.validateaddress(Addr2)
   Addr3= rpc.getnewaddress
   Pub3 = rpc.validateaddress(Addr3)
   
   ##Creation of Multisig
   multisig = rpc.createmultisig(2, [Addr1, Addr2, Addr3])
   msigaddr = multisig['address']
   msigscr = multisig['redeemScript']


   Utxo_id = rpc.sendtoaddress(msigaddr,5.00)
   rpc.generate 1
   #raw_tx_json = rpc.getrawtransaction(Utxo_id,1)
   #p Utxo_id

   raw_tx_json = rpc.getrawtransaction(Utxo_id , 1)
   utxo_os = raw_tx_json['vout'][0]['scriptPubKey']['hex']
   

   Addr4 = rpc.getnewaddress()

   tx_part1 = [Hash["txid",Utxo_id,"vout", 0]]
   tx_part2 = Hash[Addr4,2]
   raw_tx = rpc.createrawtransaction(tx_part1,tx_part2 , 225)

   Addr1_privk=rpc.dumpprivkey(Addr1)
   Addr2_privk=rpc.dumpprivkey(Addr2)

   signed_raw_tx_json = rpc.signrawtransaction(raw_tx,[Hash["txid",Utxo_id,"vout",0, "scriptPubKey" ,utxo_os, "redeemScript", msigscr ]] , [ Addr1_privk, Addr2_privk] )

   signed_raw_tx = signed_raw_tx_json['hex']
   

   #p rpc.sendrawtransaction(signed_raw_tx ,true ) ###gives error when block count is less than locktime
   rpc.generate 3
   p rpc.sendrawtransaction(signed_raw_tx ,true ) ####works fine
   p rpc.getblockcount

end

