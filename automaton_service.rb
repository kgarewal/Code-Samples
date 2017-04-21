####################################################################################
# AutomatonService: Simple machine that instantiates a finite state machine for each 
# client request when a request is pushed from the queue. May perform some
# initialization on the FSM
####################################################################################

require 'abstract_service'

module ServiceLayer
  
   
  ##############################
  # Class AutomatonService
  ##############################
  class AutomatonService < AbstractService
    QUEUE_SLEEP  = 2
    @queue = :fsm_queue 
    
    # Public : initialize - create job thread
    def initialize
      job_processor
    end

    ################################################################    
    # create a finite state machine in a new thread - called from 
    # the Resque Polling Thread
    ################################################################
    def self.perform(request_entity)
      ret = pre_process_job(request_entity)
      create_finite_state_machine(request_entity) if ret
    end
    
    private
    
    #################################################
    # Private: Thread - polls the queue for jobs 
    # Create a new Finite State Machine In it's
    # thread for each job
    #################################################
    def job_processor
      queue_thread = Thread.new {
        while(true) do
          sleep QUEUE_SLEEP
          klass, args = Resque.reserve(:fsm_queue)
          klass.perform(*args) if klass.respond_to? :perform
        end
      }
    end

    ################################################
    # Private: create a finite state machine in a
    # new thread
    ################################################
    def self.create_finite_state_machine(request_entity)
      fsm_thread = Thread.new {
        fsm = ServiceLayer::FSMService.new(request_entity)
        ServiceLayer::LoggerService.write("Automaton Started for request entity : #{request_entity}")
        fsm.start(request_entity, fsm)
        sleep()  
      }
    end
        
    #######################################################
    # Private: pre-process_job : pre_process_job: 
    # pre_process a client request before creating a finite
    # state machine
    #######################################################
    
    def self.pre_process_job(request_entity)
      # Automaton will preprocess requests here
      true
    end
    
  end    
end
