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
   myaddr = "mpMncoyDzjjgP7QjD1ouj946dikX58zEtS";
   loop do
      puts "What would you like to do?"
      puts "1: Print My Address"
		puts "2: Generate new Address"
      puts "3: Create Multisig Address"
      puts "4: Print my Balance"
      puts "5: Send BTC to Address"
      puts "6: Send BTC from multisig address"
      puts "7: Find Balance of any address"
      puts "10: Exit"
      inp = gets.chomp
      inp = inp.to_i
		if (inp == 1)
       		puts "Address : " + myaddr + "\n\n"
		end
		if (inp == 2)
				myaddr = rpc.getnewaddress;
       		puts "New Address : " + myaddr + "\n\n"
		end
		if (inp == 3)
				Addr1= rpc.getnewaddress
   			Pub1 = rpc.validateaddress(Addr1)
   			Addr2= rpc.getnewaddress
   			Pub2 = rpc.validateaddress(Addr2)
   			Addr3= rpc.getnewaddress
   			Pub3 = rpc.validateaddress(Addr3)
   			##Creation of Multisig
			 	multisig = rpc.createmultisig(2, [Addr1, Addr2, Addr3])
   			msigaddr = multisig['address']
   			puts "Multisig Reedeem Script : " + multisig['redeemScript'] + "\n\n"
   			puts "Mulsig Address : " + msigaddr + "\n\n"
   			puts "Would you like to see the private keys for this address?Yes / No : \n"
   			choice = gets.chomp
   			if(choice == "Yes")
   				p rpc.dumpprivkey(Addr1)
   				p rpc.dumpprivkey(Addr2)
   				p rpc.dumpprivkey(Addr3)
				end
				rpc.addmultisigaddress(2, [Addr1, Addr2, Addr3])
		end
		if (inp == 4)
				mybal = 0
				list  = rpc.listunspent(6, 9999999, [myaddr])
				for i in list
					mybal += i['amount']
				end
       		puts "Balance : " + mybal.to_s + "\n\n"
		end
		if (inp == 5)
				puts "Please enter address you would like to send BTC to..."
				addr = gets.chomp
				puts "How many Bitcoins would you like to send?"
				amt = gets.chomp
				amt = amt.to_f
				puts "Transaction ID: " + rpc.sendtoaddress(addr, amt) + "\n\n"
		end
		if (inp == 6)
				lcktime = 0
				puts "Please enter multisig address you would like to send BTC FROM"
				muladdr = gets.chomp
				puts "Please enter address you would like to send BTC TO..."
				addr = gets.chomp
				puts "How many Bitcoins would you like to send?"
				amt = gets.chomp
				amt = amt.to_f
				puts "Please enter any two private keys for the mulltisig address:\n"
   			Addr1_privk = gets.chomp
   			puts "Enter another private key:\n"
   			Addr2_privk = gets.chomp
				puts "Please enter the Reedeem Script for the mulltisig address:\n"
   			msigscr = gets.chomp
				list  = rpc.listunspent(6, 9999999, [muladdr])
				for i in list
					if (amt <= i['amount'])
						Utxo_id = i['txid']
					end
				end
				raw_tx_json = rpc.getrawtransaction(Utxo_id , 1)
   			utxo_os = raw_tx_json['vout'][0]['scriptPubKey']['hex']
				tx_part1 = [Hash["txid",Utxo_id,"vout", 0]]
   			tx_part2 = Hash[addr,amt]
   			puts "Would you like to have a Locktime on the transaction?\nYes/No: "
   			lck = gets.chomp
   			if(lck == "Yes")
					puts "Current Block Height : " + (rpc.getblockcount).to_s + "\nWhat would you like to set as LockTime?\n"
					lcktime = gets.chomp
					raw_tx = rpc.createrawtransaction(tx_part1,tx_part2, lcktime.to_i)
				end
				if(lck == "No")
					raw_tx = rpc.createrawtransaction(tx_part1,tx_part2)
				end
  				signed_raw_tx_json = rpc.signrawtransaction(raw_tx,[Hash["txid",Utxo_id,"vout",0, "scriptPubKey" ,utxo_os, "redeemScript", msigscr ]] , [ Addr1_privk, Addr2_privk] )
   			signed_raw_tx = signed_raw_tx_json['hex']
   			if(lck == "Yes")
   				loop do 
   					break if(rpc.getblockcount>=lcktime.to_i)
					end
				end
				puts "Transaction ID: " + rpc.sendrawtransaction(signed_raw_tx ,true ) + "\n\n"
		end
		if (inp == 7)
				puts "Please enter an address:\n"
				addr = gets.chomp
				mybal = 0
				list  = rpc.listunspent(6, 9999999, [addr])
				for i in list
					mybal += i['amount']
				end
       		puts "Balance : " + mybal.to_s + "\n\n"
		end
   	   break if (inp ==10)
   	end
end
