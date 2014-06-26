####################################################################################
# FSMService: Finite State Machine Service For Approval Workflows
# Runs in a thread. Created by the Automaton Service.
####################################################################################

require 'abstract_service'
require 'entity_parser'

module ServiceLayer
  
  ########################
  # Class FSMService
  ########################
  
  class FSMService < AbstractService

    attr_accessor  :current_archetype, :current_state, :approval_groups, :approval

    
    ##################################################################
    # initialize a new FSM to process a client request
    # receives a request entity hash
    # @approval_groups : array of approval group objects
    # @approval : approval object
    ##################################################################
    def initialize(request_entity)
      @request_entity =  request_entity  
      @approval_groups = []
      @approval = nil
    end
    
    ###################################################################
    # start the FSM - Parses the request entity. Instantiates the DCI
    # receives a pointer to the instantiated fsm and the request entity
    ###################################################################
    def start(request_entity, fsm = nil)
      @fsm = fsm 
      ServiceLayer::LoggerService.write("FSM Started for request entity : #{request_entity}")
      fsm.extend(EntityParser)
      ret = parse(request_entity)
      ServiceLayer::LoggerService.write("Parser returns : #{ret} : #{request_entity}")
      
      if ret[:status] == :error
        send_error_notification(request_entity, ret)
        return ret
      else  
        ServiceLayer::LoggerService.write("DCI Started  Archetype - #{ret[:archetype] } - State - #{ret[:state]} : #{request_entity}")
        create_dci(request_entity, ret[:archetype], ret[:state] )
      end
    
    end
    
    #############################################################
    # create_dci: creates the data context interaction for the  
    # fsm
    #############################################################
    
    def create_dci(request_entity, archetype, state)
      if archetype == :standard_client_request
        rcontext = StandardRequestContext.new(request_entity, @fsm, state)
        @current_archetype = :standard_client_request
        @current_state = state
        ServiceLayer::LoggerService.write("DCI Context Starting")
        ret = rcontext.call(request_entity["entity"]["approval_groups"])
        ServiceLayer::LoggerService.write("FSM transitioning to #{ret}")
        fsm_transition(ret) 
      end
      
    end
    
    private    
    
    ##############################################################
    # Private : fsm_transition : the machine updates itself and 
    # transits to the next stage. Receives a hash 
    ###############################################################
    
    def fsm_transition( transit)
      @approval_groups << transit[:approval_groups] if transit.has_key?(:approval_groups)
      @approval_groups.uniq if transit.has_key?(:approval_groups)
      @approval = transit[:approval] if transit.has_key?(:approval)
      @archetype = transit[:archetype] if transit.has_key?(:archetype)
      @state = transit[:state] if transit.has_key?(:state)
    end
    
    ##############################################################
    # Private : send_error_notification
    ##############################################################
    def send_error_notification(request_entity, ret)
   
    end
       
  end
end
