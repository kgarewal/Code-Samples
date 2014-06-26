####################################################################################
# NotificationService: Notification Service For Approval notifications
####################################################################################

require 'abstract_service'

module ServiceLayer
   
  ########################
  # Class FSMService
  ########################
  
  class NotificationService < AbstractService
    @queue = :notification_queue 
    
    # Resque interface
    def self.perform(notification )
    
    end
    
    ######################################################
    # Create an exemplar file to be fetched by a client
    ######################################################
    
    def create_exemplar(exemplar_filename)
      File.copy_stream("#{Rails.root}/exemplars/canonical_exemplar.gif", "#{Rails.root}/exemplars/#{exemplar_filename}") 
    end
    
    ######################################################
    # delete an exemplar file
    ######################################################
    
    def delete_exemplar(exemplar_filename)
      File.delete("#{Rails.root}/exemplars/#{exemplar_filename}") if File.exist?("#{Rails.root}/exemplars/#{exemplar_filename}")      
    end
    
    #######################################################
    # test that an exemplar has been accessed
    #######################################################
    
    def accessed_exemplar?(exemplar_file)
      
      #mtime =  File.mtime("#{Rails.root}/exemplars/#{exemplar_file}").to_i.to_s
      #atime =  File.atime("#{Rails.root}/exemplars/#{exemplar_file}").to_i.to_s
      
      return File.atime("#{Rails.root}/exemplars/#{exemplar_file}").to_i >
        File.ctime("#{Rails.root}/exemplars/#{exemplar_file}").to_i
    end
    
    
    
  end
end



