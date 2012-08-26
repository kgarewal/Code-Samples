################################################################################
# RSpec file for The Torrent Model
# copyright: karan singh garewal
################################################################################


require "spec_helper"


#######################################
#  Describe The Torrent Model 
#######################################

describe  Torrent   do

    before(:all)  do
        @info_hash = "1234567890123456789012345678901234567890"
        
    end
    

#######################################################################
# Table torrents to index torrent files exists
# exists? returns false if the table is empty. True otherwise
#######################################################################

it "has a table torrents to index torrent files"   do

      pending
      
       Torrent.exists?.should == false

end



      ######################################################################
      #  it creates a torrent record
      ######################################################################

      it "creates a torrent record"  do
          
          pending
          
          @torrent =  Torrent.new(
              {:name => "test.torrent",
               :metainfo_attributes => {
               :name =>"test.torrent",
               :announce => "127.0.0.1", 
               :announce_list =>"", 
               :encoding => "bencode",
               :source_file => "test.ogv",
               :comment => "", 
               :created_by => "Ruby VoD Simulator"},
               :description => "desc", 
               :category => "sci-fi",
               :keywords => "cat", 
               :email => "k.singh@fido.com",
               :info_hash => "1234567890123456789012345678901234567890"}
              )
          
          @torrent.build_metainfo
          @torrent.save.should_not == false
          
      end



######################################################################
# It should not create a record which does not have a info_hash
######################################################################

it "should not create a record which does not have a torrent name" do

        pending
        
        torrent  = Torrent.new(:description =>  "test",
                               :category => 'sci-fi', :keywords => "a b c d",
                               :email => "f@efg")

        torrent.save.should == false               

end



###############################################################################
# It should not create a record if the info dictionary does not have a 40 byte
# SHA1 hex encoded Hash
###############################################################################

it "should not create a record when the info_hash attribute does not have length 40" do


        pending
        
        torrent  = Torrent.new(
                               :name  =>  "name.torrent",
                               :description =>  "test",
                               :category => 'sci-fi', 
                               :keywords => "a b c d",
                               :email => "foo@fi.com"

                               )

        torrent.save.should == false               

        
        torrent  = Torrent.new(
                               :name => "name.torrent",
                               :description =>  "test",
                               :info_hash => "1234567890123456789012345678901234567890",
                               :category => 'sci-fi',
                               :keywords  => "cat",
                               :email => "foo@smith.com"
                               )

        torrent.save.should ==  true             

        
end



###############################################################################
# It does not create a record when the info_hash is not unique
###############################################################################

it "should not create a record when the info_hash attribute does not have length 20" do


        pending
               
        torrent  = Torrent.new(
                               :name => "name.torrent",
                               :description =>  "test",
                               :info_hash => "1234567890123456789012345678901234567890",
                               :category => 'sci-fi',
                               :keywords  => "cat",
                               :email => "foo@smith.com"
                               )

        torrent.save.should ==  true             

        
        torrent  = Torrent.new(
                               :name => "name2.torrent",
                               :description =>  "test2",
                               :info_hash => "1234567890123456789012345678901234567890",
                               :category => 'sci-fi',
                               :keywords  => "cat",
                               :email => "foo@smith.com"
                               )

        torrent.save.should ==  false             

        
end



##############################################################################
# It does not create a record when the torrent does not have a description
##############################################################################

it "should not create a record when the torrent does not have a description" do

        pending
       
        torrent  = Torrent.new(:name =>  "new.torrent", 
                               :category => 'sci-fi',
                               :info_hash   => "1234567890123456789012345678901234567890",
                               :keywords => "a b c d",
                               :email => "foo@fido.com"
                              )

        torrent.save.should == false               

        
         torrent  = Torrent.new( :name =>  "new.torrent", 
                                 :description =>  "desc", 
                                 :category => 'sci-fi',
                                 :info_hash   => "1234567890123456789012345678901234567890",
                                 :keywords => "a b c d",
                                 :email => "foo@fido.com"
                              )

         torrent.save.should == true               
        
        
end


##############################################################################
# It does not create a record when the torrent does not have a description
##############################################################################

it "does not create a record when the torrent does not have a category" do

       
       pending
      
       torrent  = Torrent.new( :name =>  "new.torrent", 
                               :info_hash   => "1234567890123456789012345678901234567890",
                               :keywords => "a b c d", 
                               :category => "sci-fi",
                               :email => "fido@foo.com"
                               )

       torrent.save.should == false               

       
       torrent  = Torrent.new( :name =>  "new.torrent", 
                               :description => "desc",
                               :info_hash   => "1234567890123456789012345678901234567890",
                               :keywords => "a b c d", 
                               :category => "sci-fi",
                               :email => "fido@foo.com"
                               )

       torrent.save.should == true
       
       
end





###############################################################################
# It should not create a record when the torrent does not have an email address
###############################################################################

it "should not create a record when the torrent does not have a email address" do

        pending 
               
        torrent  = Torrent.new( :name =>  "new.torrent", 
                               :description => "desc",
                               :info_hash   => "1234567890123456789012345678901234567890",
                               :keywords => "a b c d", 
                               :category => "sci-fi"
                               )

        torrent.save.should == false               

end


##############################################################################
# It should not create a record when the torrent does not have a valid email
##############################################################################


it "should not create a record when the torrent does not have a valid email" do

      pending
      
       ["abc", "a@@bc", "@", "@123", ".@.", "a@b", "~~.xyx", "123@!~]" ].each  do  |p|
               torrent  = Torrent.new(:name =>  "new.torrent", 
                                      :description => "simple",
                                      :info_hash   => "1234567890123456789012345678901234567890",
                                      :category => 'sci-fi', 
                                      :keywords => "a b c d",  
                                      :email =>  p)

                torrent.save.should == false               
       end
       
end





################################################################################
# it  creates a torrent record 
################################################################################

it "creates a torrent record" do
 
        pending
        
        torrent  = Torrent.new(:name =>  "new.torrent",
                               :description => "simple", 
                               :info_hash   => "1234567890123456789012345678901234567890",
                               :category => "action", 
                               :keywords => 'test',
                               :email => "j.smith@smith.com" )
 
        torrent.should_not == nil
        torrent.name.should == "new.torrent"
        torrent.category.should == "action"
        torrent.save.should == true
        Torrent.count.should == 1
        
end





################################################################################
# the seeds value must be greater than or equal to zero
################################################################################

it "must have a seed value greater than or equal to zero"  do


        pending
      
        torrent  = Torrent.new(:name =>  "new.torrent", 
                               :description => "simple", 
                               :info_hash   => "1234567890123456789012345678901234567890",
                               :category => "action", 
                               :keywords => "cat",
                               :email => "j.smith@foo.com",
                               :seeds => -1 )          
        
        torrent.save.should == false 
        
        
         torrent  = Torrent.new(:name =>  "new.torrent", 
                               :description => "simple", 
                               :info_hash   => "1234567890123456789012345678901234567890",
                               :category => "action", 
                               :keywords => "cat",
                               :email => "j.smith@foo.com",
                               :seeds => 10 )          
        
         torrent.save.should == true 
        
        
end



################################################################################
# the leechers value must be greater than or equal to zero
################################################################################


it "must have a leechers value greater than or equal to zero"  do


        pending
      
        torrent  = Torrent.new(:name =>  "new.torrent", 
                               :description => "simple",
                               :info_hash   => "1234567890123456789012345678901234567890",
                               :category => "action",
                               :keywords => "cat",
                               :email => "j.smith@foo.com",
                               :leechers => -1 )          
        
        
        torrent.save.should == false 
        
        torrent  = Torrent.new(:name =>  "new.torrent", 
                               :description => "simple",
                               :info_hash   => "1234567890123456789012345678901234567890",
                               :category => "action",
                               :keywords => "cat",
                               :email => "j.smith@foo.com",
                               :leechers => 30)          
        
        
        
        torrent.save.should == true 
                
        
        
end


################################################################################
# the health value must be greater than or equal to 0 and less than or equal to 100
################################################################################

it "must have a health value in the range from 0 to 100"  do

        pending

        torrent  = Torrent.new(:name =>  "new.torrent", 
                               :description => "simple", 
                               :info_hash   => "1234567890123456789012345678901234567890",
                               :category => "action",
                               :keywords => "cat",
                               :email => "j.smith@smith.com",
                               :health => 300 )          
        
                               torrent.save.should == false 
        
         torrent  = Torrent.new(:name =>  "new.torrent", 
                               :description => "simple", 
                               :info_hash   => "1234567890123456789012345678901234567890",
                               :category => "action",
                               :keywords => "cat",
                               :email => "j.smith@smith.com",
                               :health => 90 )          
        
         torrent.save.should == true
                                
                                                              
                               
   end   # end of test


 
   ##########################################################################
   # A Torrent Server initiated tracker query fails for a ficitious info_hash
   ##########################################################################
   
   it "a torrent table updte fails if a query to a tracker has an invalid info_hash " do
      
       pending
       
       # Create a torrent record
       
       torrent  = Torrent.new( :name =>  "new.torrent", 
                               :description => "desc",
                               :info_hash   => "1234567890123456789012345678901234567890",
                               :keywords => "a b c d", 
                               :category => "sci-fi",
                               :email => "fido@foo.com"
                               )

       torrent.save.should == true
              
       
       HTTParty.stub(:get).and_return(['{"failure":"info_hash record announce record does not exist"}'])
       
       #Torrent.tracker_update
       
   end



   ##########################################################################
   # A Torrent Server initiated tracker query suceeeds for a valid info_hash
   # TODO : fix response stub for HTTParty
   ##########################################################################
   
   it "updates the tracker database if the query returns valid dat " do
       
       pending
       
       torrent  = Torrent.new( :name =>  "new.torrent", 
                               :description => "desc",
                               :info_hash   => @info_hash,
                               :keywords => "a b c d", 
                               :category => "sci-fi",
                               :email => "fido@foo.com"
                               )

       torrent.save.should == true
   
       
       #HTTParty.stub(:get).and_return(response )
      
       #HTTParty.stub(:get).and_return( '{"seeders":"tracker_reply[0][:seeders]", "leechers":"tracker_reply[0][:leechers]"}' )
       
       Torrent.tracker_update
       
   end
   

end   # end of class




