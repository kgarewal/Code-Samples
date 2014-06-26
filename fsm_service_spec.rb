require "spec_helper"

describe ServiceLayer::FSMService do
  let(:bad_entity_type) { "string" } 
  let(:good_approval_group) { { "name" => 'engineer', "description" => 'albuquerque',"edir_group_name" => 'Kbe' } }
  
  let(:no_dups) {
    { "quote_id" =>  '1234RTUP',
      "entity" => {
      "approval_groups" =>  [
                          {
                            "name" => 'engineer',
                            "edir_group_name" =>  'kbe',
                            "notification_group" => '',
                            "datacenter" => '',
                            "one_off_group" => '',
                            "region" => ''
                          } 
                        ]
     } 
    }
  }
  
    let(:good_request_entity) {
    { "quote_id" =>  '1234RTUP',
      "entity" => {
           "approval_groups" =>  [
                          {
                            "name" => 'sales',
                            "description" => 'us sales',                            
                            "edir_group_name" => 'sales_edir',
                            "notification_group" => '',
                            "datacenter" => '',
                            "one_off_group" => '',
                            "region" => ''
                          } 
                        ]
     } 
    }
  }

  let(:new_approval_group_record) {
    { "quote_id" =>  'WQERT',
      "entity" => {
      "approval_groups" =>  [
                          {
                            "name" => 'manager',
                            "description" => 'us sales',                            
                            "edir_group_name" => 'sales_edir',
                            "notification_group" => '',
                            "datacenter" => '',
                            "one_off_group" => '',
                            "region" => ''
                          } 
                        ]
     } 
    }
  }

  let(:good_request_entity) {
    { "quote_id" =>  '1234RTUP',
      "entity" => {
      "approval_groups" =>  [
                          {
                            "name" => 'sales',
                            "description" => 'us sales',                            
                           "edir_group_name" => 'sales_edir',
                            "notification_group" => '',
                            "datacenter" => '',
                            "one_off_group" => '',
                            "region" => ''
                          } 
                        ]
     } 
    }
  }
  
  
  let(:datacenter) {
    { "quote_id" =>  '1234RETQ',
      "entity" =>   {
      "approval_groups" =>  [
                          {
                            "name" => 'sales VP',
                            "description" => 'us sales',                            
                            "edir_group_name" =>'sales_edir',
                            "notification_group" => '',
                            "datacenter" => 'US West',
                            "one_off_group" => '',
                            "region" => ''
                          } 
                        ]
     } 
   }
  }
  
  
  let(:no_approval_groups) {
    { "description" =>  'sales',
      "quote_id" => '123ABC',
      "entity" => { "name" => "csw" } 
   }
  }

  let(:non_array_approval_groups) {
    { "description" =>  'sales',
      "quote_id" => '123ABC',
      "entity" => {
      "approval_groups" => 'just a string'    
    } 
   }
  }

  let(:empty_array_approval_groups) {
    { "description" =>  'sales',
      "quote_id" => '123ABC',
      "entity" => {
      "approval_groups" => []    
    } 
    }
  }

  let(:no_name_approval_group) {
    { "description" =>  'sales',
      "quote_id" => '123ABC',
      "entity" => {
      "approval_groups" => [ {"name" => 'foo'}, { b: 'a'} ]    
    } 
    }
  }
 
  let(:region) {
    { "quote_id" =>  '1234RETQ',
      "entity" => {
      "approval_groups" =>  [
                          {
                            "name" => 'sales ',
                            "description" => 'midwest sales',                            
                           "edir_group_name" => 'sales_edir',
                            "notification_group" => '',
                            "datacenter" => '',
                            "one_off_group" => '',
                            "region" => 'midwest'
                          } 
                        ]
     } 
    }
  }
  
  let(:one_off_group) { 
    { "quote_id" =>  '1234RETQ',
      "entity" =>  {
      "approval_groups" =>  [
                          {
                            "name" => 'sales ',
                            "description" => 'midwest sales',                            
                            "edir_group_name" => 'sales_edir',
                            "notification_group" => '',
                            "datacenter" => '',
                            "one_off_group" => '12YURZ',
                            "region" => ''
                          } 
                        ]
      }           
     } 
   }
  
  it "creates a finite state machine service for a Queued job" do
    #pending
    fsm = ServiceLayer::FSMService.new ( {b: :a})
    fsm.nil?.should == false
  end

  it "starts a finite state machine" do
    #pending
    fsm = ServiceLayer::FSMService.new ( {b: :a})
    fsm.respond_to?(:start).should be_true
  end

  it "validates that the request entity is a Hash" do
    #pending
    fsm = ServiceLayer::FSMService.new(bad_entity_type)
    ret = fsm.start(bad_entity_type, fsm)
    ret[:status].should == :error
    ret[:error].include?('request entity has invalid type').should be_true
  end
    
  it "returns an error if the request entity does not have an approval_groups key" do
    #pending
    fsm = ServiceLayer::FSMService.new(no_approval_groups)
    ret = fsm.start(no_approval_groups, fsm)
    ret[:status].should == :error
    ret[:error].include?('Request entity does not have approval groups').should be_true
  end
  
  it "returns an error if the request entity approval_groups value is not an array" do
    #pending
    fsm = ServiceLayer::FSMService.new(non_array_approval_groups)
    ret = fsm.start(non_array_approval_groups, fsm)
    ret[:status].should == :error
    ret[:error].include?('Request entity does not have approval groups').should be_true
  end
  
  it "returns an error if the request entity approval_groups value is an empty array" do
    #pending
    fsm = ServiceLayer::FSMService.new(empty_array_approval_groups)
    ret = fsm.start(empty_array_approval_groups, fsm)
    ret[:status].should == :error
    ret[:error].include?('Request entity does not have any approval groups content').should be_true
  end

  it "returns an error if each approval group does not contain a name key" do
    #pending
    fsm = ServiceLayer::FSMService.new(no_name_approval_group)
    ret = fsm.start(no_name_approval_group, fsm)
    ret[:status].should == :error
    ret[:error].include?('Approval groups missing key :name').should be_true
    
  end
    
 it "parses a client request entity" do
   #pending
   fsm = ServiceLayer::FSMService.new(good_request_entity)
   fsm.stub(:create_dci).and_return(true)
   fsm.start(good_request_entity, fsm).should == true
 end

 it "returns an archetype and a initial state for a valid request entity" do
   #pending
   fsm = ServiceLayer::FSMService.new(good_request_entity)
   fsm.stub(:create_dci).and_return(true)
   fsm.start(good_request_entity, fsm)
   ret = fsm.parse(good_request_entity)
   ret.has_key?(:archetype).should be_true
   ret.has_key?(:state).should be_true

 end
 
 it "fetches an approval_group record and adds it to it's context" do
   #pending
   fsm = ServiceLayer::FSMService.new(good_request_entity)
   fsm.start(good_request_entity, fsm)
   expect(fsm.approval_groups.size).to be(1) 
   fsm.approval.nil?.should_not == nil 
 end
 
 it "creates a new approval group record and adds it to it's context" do
   #pending
   fsm = ServiceLayer::FSMService.new(new_approval_group_record)
   fsm.should_not == nil
   expect {fsm.start(new_approval_group_record, fsm) }.to change{ V1::ApprovalGroup.count }.by(1)
 end
  
 it "does not add a approval group record if it already exists" do
   #pending
   fsm = ServiceLayer::FSMService.new(datacenter)
   fsm.should_not == nil
   expect {fsm.start(datacenter, fsm) }.to change{ V1::ApprovalGroup.count }.by(1)

   fsm.start(datacenter, fsm)
   expect {fsm.start(datacenter, fsm) }.to change{ V1::ApprovalGroup.count }.by(0)
 end

 it "adds a approval group record by datacenter" do
   #pending
   fsm = ServiceLayer::FSMService.new(datacenter)
   fsm.should_not == nil
   expect{ fsm.start(datacenter, fsm) }.to change{ V1::ApprovalGroup.count }.by(1) 
 end
 
 it "updates it's group object array if an approval group record for a datacenter is added" do
   #pending
   fsm = ServiceLayer::FSMService.new(datacenter)
   fsm.should_not == nil
   expect{ fsm.start(datacenter, fsm) }.to change{ fsm.approval_groups.size }.by(1) 
 end

 
 it "adds a  approval group record by region" do
   #pending
   fsm = ServiceLayer::FSMService.new(region)
   fsm.should_not == nil
   expect{ fsm.start(region, fsm) }.to change{ V1::ApprovalGroup.count }.by(1) 
 end
 
 it "adds a approval group record by one-off-group" do
   #pending
   fsm = ServiceLayer::FSMService.new(one_off_group)
   fsm.should_not == nil
   #fsm.approval_groups.size.should == 1 
   expect{ fsm.start(one_off_group, fsm) }.to change{ V1::ApprovalGroup.count }.by(1) 
 end
 
 it "updates it's group object array if an approval group record for an one_off_group is added" do
   #pending
   fsm = ServiceLayer::FSMService.new(one_off_group)
   fsm.should_not == nil
   expect{ fsm.start(one_off_group, fsm) }.to change{ fsm.approval_groups.size }.by(1) 
 end

 
end