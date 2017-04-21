##########################################################################################
# implement a facade service to hide services using the GoF facade design pattern
##########################################################################################

require "spec_helper"
require 'json'

describe ServiceLayer::FacadeService do
  
  let(:token_request) {  "{\"status\":\"OK\",\"token\":\"12345678901234567890123456789012\"}"  }
  let(:bad_email) {  }
  let(:no_token) { "{\"quote_id\": \"ACCDEF\", \"archetype\":\"g\", \"key\":\"value\"}" }
  let(:bad_token) { "{\"token\":\"1234567890098765432112345678909\", \"archetype\": \"genus\", \"quote_id\":\"ACCDEF\", \"J\":\"K\"}" }
  let(:no_genus) { '{"token":"stubbed", "quote_id":"ACCDEF", "J":"K"}' }
  let(:malformed) { "some arbitrary string" }
  let(:good_request) { "{\"token\":\"5bdaf947236852c7f44130c9cb2bc207\", \"quote_id\":\"FR-0089\", 
  \"entity\": { \"name\": \"abc\", \"approval_groups\": [{\"name\": \"Hong Kong Quote\", 
  \"description\":\"EDHK7\", \"edir_group_name\": \"HK7\" }] }, \"description\":\"Datacenter A\" }" }
  let(:bad_request) { "{\"token\":\"5bdaf947236852c7f44130c9cb2bc207\", \"quote_id\":\"FR-0089\", 
    \"entiy\": { \"name\": \"HK-quote\", \"approval_groups\": [{\"name\": \"Hong Kong Quote\", 
  \"description\":\"EDHK7\", \"edir_group_name\": \"HK7\" }] }, \"description\":\"Datacenter A\" }" }

  it "instantiates a FacadeService Singleton" do
    #pending
    expect( ServiceLayer::FacadeService.instance).to_not eq(nil)
  end
  
  it "is a singleton that responds to the token method" do
    #pending
    ServiceLayer::FacadeService.instance.respond_to?(:token).should be_true
  end
  
  it "does not validate a request if an authentication token is not presented" do
    #pending
    expect(ServiceLayer::FacadeService.instance.entity(no_token)).to eql( { status: "no authentication key" })
  end
  
  it "does not accept a malformed json request form a client" do
    #pending
    expect(ServiceLayer::FacadeService.instance.entity(malformed)).to eql( { status: "invalid hash" })
  end
  
  
  it "accepts a valid client request" do
    #pending
    ServiceLayer::FacadeService.instance.stub(:facade_authenticate).and_return( {status: true} )
    ServiceLayer::FacadeService.instance.stub(:persist).and_return( {status: true} )
    ServiceLayer::FacadeService.instance.stub(:enqueue).and_return( true)
    expect(ServiceLayer::FacadeService.instance.entity(good_request)).to eql( { status: "request entity is queued" })
  end
 
  it "does not accept a client request with an invalid authentication token" do
    #pending
    ServiceLayer::FacadeService.instance.stub(:facade_authenticate).and_return( {status: 'authentication failed'} )
    expect(ServiceLayer::FacadeService.instance.entity(bad_token)).to eql( { status: "authentication failed" })
  end

  it "does not accept a client request when an email address is not provided" do
    #pending
    ret = ServiceLayer::FacadeService.instance.token("127.0.0.1", "")
    ret[:status].should == 'bad email address'
  end
      
  it "generates a 32 byte MD5 authentication token" do
    #pending
    ret = ServiceLayer::FacadeService.instance.token("127.0.0.1", "foo@bar.net")
    ret[:token].length.should == 32
  end
  
  it "does not generates a session token for invalid email addresses" do
    #pending
    ret = ServiceLayer::FacadeService.instance.token("127.0.0.1", "foobar.net")
    ret[:token].length.should == 0
  end

  it "persists a session to the facade_sessions table" do
    #pending
    expect{ServiceLayer::FacadeService.instance.token("127.0.0.1", "foobar@bar.net")}.to change{FacadeSession.count}.by(1)
  end
  
  it "does not persist a session request with invalid parameters to the facade_sessions table" do
    #pending
    expect{ServiceLayer::FacadeService.instance.token("127.0.0.1", "foobarbar.net")}.to change{FacadeSession.count}.by(0)
  end 
  
  it "returns a no request made message if the client does not make a request in a entity request" do
    #pending
    expect(ServiceLayer::FacadeService.instance.entity()).to eql({ status: 'no request made'})
  end
  
  it "returns a no request made message if the entity request does not contain an entity key" do
    #pending
    expect(ServiceLayer::FacadeService.instance.entity()).to eql({ status: 'no request made'})
  end

    
  it "returns a invalid hash message if the entity request is not a valid json string" do
    #pending
    expect(ServiceLayer::FacadeService.instance.entity(malformed)).to eql({ status: 'invalid hash'})
  end
  
  it "returns a no authentication key message if the entity request does not contain a token key" do
    #pending
    expect(ServiceLayer::FacadeService.instance.entity(no_token)).to eql({ status: 'no authentication key'})
  end

  it "returns an authentication failed message for a bad authentication token" do
    #pending
    expect(ServiceLayer::FacadeService.instance.entity(bad_token)).to eql({ status: 'authentication failed'})
  end
 
  it "creates a Facade record for a valid request entity" do
    #pending
    ServiceLayer::FacadeService.instance.stub(:facade_authenticate).and_return({status: true})
    expect { ServiceLayer::FacadeService.instance.entity(good_request) }.to change{V1::Facade.count}.by(1)
  end

  it "returns a entity not enqueued message if the message is not Reqsue enqueued" do
    #pending
    ServiceLayer::FacadeService.instance.stub(:facade_authenticate).and_return({status: true})
    ServiceLayer::FacadeService.instance.stub(:persist).and_return({status: true})
    ServiceLayer::FacadeService.instance.stub(:enqueue).and_return(false)
    expect(ServiceLayer::FacadeService.instance.entity(good_request)).to eql({ status: 'request entity not enqueued'})
  end
  
  it "enqueues a request entity" do
    #pending
    ServiceLayer::FacadeService.instance.stub(:facade_authenticate).and_return({status: true})
    expect(ServiceLayer::FacadeService.instance.entity(good_request)).to eql({status: "request entity is queued"})
  end

  it "creates an entity record" do
    #pending
    ServiceLayer::FacadeService.instance.stub(:facade_authenticate).and_return({status: true})
    expect { ServiceLayer::FacadeService.instance.entity(good_request) }.to change{Entity.count}.by(1)
  end
  
  it "does not create an entity record for a bad request" do
    #pending
    ServiceLayer::FacadeService.instance.stub(:facade_authenticate).and_return({status: true})
    expect { ServiceLayer::FacadeService.instance.entity(bad_request) }.to change{Entity.count}.by(0)
  end

  it "does not create a facade record for a bad request" do
    #pending
    ServiceLayer::FacadeService.instance.stub(:facade_authenticate).and_return({status: true})
    expect { ServiceLayer::FacadeService.instance.entity(bad_request) }.to change{V1::Facade.count}.by(0)
  end

  it "does not enqueue a client request for a bad request" do
    #pending
    ServiceLayer::FacadeService.instance.stub(:facade_authenticate).and_return({status: true})
    expect(ServiceLayer::FacadeService.instance.entity(bad_request)).to_not eql({status: "request entity is queued"})
  end

  
end
  
