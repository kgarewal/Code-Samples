####################################################################################
# FacadeService: Singleton Class providing facade services to the Approval System
####################################################################################

require 'singleton'
require 'abstract_service'
require 'digest/md5'
require 'json'
require 'resque'

module ServiceLayer
   
  ########################
  # Class FacadeService
  ########################
  
  class FacadeService < AbstractService
    include Singleton
   
    #############################################################
    # Public: create a MD5 hash session token. persist the 
    # session data returns a hash indicating result
    #############################################################
    def token(remote_ip, email = nil)
      
      ret = email =~ /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i 
    
      if ret 
        digest = Digest::MD5.hexdigest(Time.now.to_s) if ret
        fc = FacadeSession.new
        fc.token = digest; fc.email = email; fc.remote_ip = remote_ip
        fc.save ? error = "" : error = "record not saved"
      else
        error = "bad email address"
      end
    
      ret ?  {token: digest, status: "OK" } : { token: "", status: error }  
       
    end
    
    ##################################################################
    # Public: receives a request entity. Validates the authentication
    # token, validates the request hash. 
    # Receives a request entity from the client
    # returns a hash indicating result
    ##################################################################
    
    def entity(client_request = nil)
      return { status: 'no request made'} if client_request.nil?
      request_hash = validate_json(client_request)
      return {status: "invalid hash"} if request_hash == false
      ret = facade_authenticate(request_hash) 
      return ret if ret[:status] != true
      ret = validate_entity(request_hash)
      return ret if ret != true
      
      # persist
      ret = persist(request_hash)
      return {status: "request entity not persisted"} if ret != {status: true}
      
      return {status: "request entity not enqueued" }  if !enqueue(request_hash)
      return {status: "request entity is queued"}
    end
    
      
    private
    ######################################################
    # Private : Initialize and create a thread to delete
    # expired sessions
    ######################################################
    def initialize
      lock = Mutex.new
      
      Thread.new  {
        thread_sleep = 3600  
        while true
          sleep thread_sleep.to_i
          lock.synchronize {  
            # TODO uncomment at end of development
            #FacadeSession.delete_all(created_at.to_i.minutes > Time.now - SLEEP.to_i.minutes)
          }
        end
      }
    end
    
    #######################################################
    # private : test that string is JSON
    #######################################################
    def validate_json(str)  
      begin
        req = JSON.parse(str)  
        return req 
      rescue => exc
        return false  
      end 
    end
    
    ######################################################
    # Private: authenticate a request made by a client
    # authentication token is a MD5 hash
    ######################################################
    def facade_authenticate(request_hash)
      return { status: "no authentication key" } if request_hash["token"].nil? 
      ret = FacadeSession.find_by_token(request_hash["token"])
      return { status: "authentication failed" } if ret.nil?  
      { status: true }
    end

    ######################################################
    # Private: validate the request entity
    # receives a hash structure
    # hash must contain "token", "quote_id" keys and one
    # or more domain specific keys
    ######################################################
    def validate_entity(request_hash)
      return {status: "missing entity key"} if !request_hash.has_key?("entity") 
      ctr = 0
      request_hash.each { |key, value| ctr += 1 } 
      return { status: "empty request made" } if ctr == 2
      return {status: "invalid entity json object" } if request_hash["entity"].class.name != "Hash"
      true
    end
    
    ######################################################
    # Private : Persist The Request
    # create a facade record. Create an entity record 
    ######################################################
    def persist(request_hash)
      # create a facade record for the request entity
      fc = V1::Facade.new
      fc.quote_id = request_hash["quote_id"]
      fc.request = request_hash.to_json
      return {status: "request not persisted to facade store"} if !fc.save
      
      ec = Entity.new
      ec.request_identifier = request_hash["quote_id"]
      ec.description = request_hash["description"] if !request_hash["description"].nil?
      ec.request = request_hash.to_json
      return {status: "request not persisted to entity store"} if !ec.save
      {status: true}    
      
    end
        
    ######################################################
    # Private: enqueue a client's request entity 
    ######################################################
    def enqueue(request_hash)
      return Resque.enqueue(ServiceLayer::AutomatonService, request_hash)
    end
    
  end
end
