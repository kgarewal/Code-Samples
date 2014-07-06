#######################################################################################
# LicenseController Tests
# Mock the server call in all but one such test
#######################################################################################

require 'spec_helper'

describe LicenseController do
  render_views

  # license_no=
  # license_type=Standard
  # version=beta
  # Licenses=1
  # http://localhost:3000/add_license?


  #######################################
  #Standard-1 Seat
  #license_no=0123456789
  #license_type=Standard
  #version=alpha
  #Licenses=1
  #######################################

  it 'returns a valid view for a 2013 Standard version with one license' do
    #pending
    LicenseAPI.should_receive(:validate_add_license).with("alpha", "0123456789", "1", "Standard").and_return(
      {:code => 200, 
      :body => {"license_offering_count" => "", "license_offerings" => ['abc', 'def'], "offerings_from" => {"" => ""}, 
                "max_license_count" => "2", "maxReached" => false, "availableLicenses" => "2", "unsupportedVersion" => "", 
                "error" => ""}, 
      :error => nil})
    x = Time.now.to_i
    visit '/add_license?Version=alpha&LicenseNumber=0123456789&NumLicenses=1&license_type=Standard'
    y = Time.now.to_i
    z = (y - x)

    puts "ROUND TRIP for: returns a valid view for a 2013 Standard version with one license :  #{z.to_s} seconds"
    if z >= 5
        puts "\nEXITING DUE TO TIMEOUT\n"
    else
      #find('li:first label')['for'].should == '0000000000006800192'
      #find('li:nth(4) label')['for'].should == '0000000000006800198'
      page.should have_selector("#multiQuantity #license_options_list li", :text => "Add 1 User")
      page.should have_selector("#multiQuantity #license_options_list li", :text => "Add 2 Users")
      expect(page).to have_button('Buy!')
      expect(page).to have_selector('.offer-link a' ,text: 'Purchase by phone')
      find('.offer-link a')['onclick']
      page.should have_selector(".offer-link a", :text => "Purchase by phone")
    end
  end

  #######################################
  #I-Standard-1Seat
  #license_no=0123456789
  #license_type=Standard
  #version=beta
  #Licenses=1
  #######################################


  it 'returns a valid view for a I Standard version with one license' do
    #pending
    LicenseAPI.should_receive(:validate_add_license).with("beta", "0123456789", "1", "Standard").and_return(
      {:code => 200, 
      :body => {"license_offering_count" => "", "license_offerings" => [{"license_offer" => "1"}, {"license_offer" => "2"}], "offerings_from" => {"" => ""}, 
                "max_license_count" => "3", "maxReached" => false, "availableLicenses" => "2", "unsupportedVersion" => "", 
                "error" => ""}, 
      :error => nil})
    x = Time.now.to_i
    visit '/add_license?Version=beta&LicenseNumber=0123456789&NumLicenses=1&license_type=Standard'
    y = Time.now.to_i
    z = (y - x)
    puts "ROUND TRIP  FOR: returns a valid view for a I Standard version with one license :  #{z.to_s} seconds"

    if z >= 5
      puts "\nEXITING DUE TO TIMEOUT\n"
    else
      #find('li:first input')['value'].should == '0000000000010400042'
      #find('li:nth(4) input')['value'].should == '0000000000010400043'
      page.should have_selector("#multiQuantity #license_options_list li", :text => "Add 1 User")
      page.should have_selector("#multiQuantity #license_options_list li", :text => "Add 2 Users")
      expect(page).to have_button('Buy!')
      expect(page).to have_selector('.offer-link a' ,text: 'Purchase by phone')
      find('.offer-link a')['onclick']
      page.should have_selector(".offer-link a", :text => "Purchase by phone")
    end
  end

  it 'returns a default view if no add a license parameters are specified' do
    #pending
    x = Time.now.to_i
    visit '/add_license'
    y = Time.now.to_i
    z = (y - x)

    puts "ROUND TRIP FOR: returns a default view if no add a license parameters are specified :  #{z.to_s} seconds"
    if z.to_i >= 5
      puts "\nEXITING DUE TO TIMEOUT\n"
    else
      page.should have_content('Need To Add More Licenses?')
      find('.offer-link a')['onclick']
      expect(page).to have_selector('.offer-link a' ,text: 'Purchase by phone')
    end
  end

  it 'it returns a default view for the Standard version if the add a license parameters do not include a license number' do
    #pending
    x = Time.now.to_i
    visit '/add_license?Version=beta&NumLicenses=1&license_type=Standard'
    y = Time.now.to_i
    z = (y - x)
    puts "ROUND TRIP FOR: it returns a default view for the Standard version if the add a license parameters do not include a license number :  #{z.to_s} seconds"
    if z >= 5
      puts "\nEXITING DUE TO TIMEOUT\n"
    else
      page.should have_content('Need To Add More Licenses?')
      find('.offer-link a')['onclick']
      expect(page).to have_selector('.offer-link a' ,text: 'Purchase by phone')
  end
end



  ##################################################
  # Standard-Licenses
  # license_no=ABCDE
  # license_type=Standard
  # version=alpha
  # Licenses=2
  ##################################################

  it 'returns a valid view for a 2013 Standard version with two Licenses' do
    LicenseAPI.should_receive(:validate_add_license).with("alpha", "238045632821817", "2", "Standard").and_return(
      {:code => 200, 
      :body => {"license_offering_count" => "", "license_offerings" => [{"license_offer" => "1"}, {"license_offer" => "2"}], "offerings_from" => {"" => ""}, 
                "max_license_count" => "4", "maxReached" => false, "availableLicenses" => "2", "unsupportedVersion" => "", 
                "error" => ""}, 
      :error => nil})
    #pending
    x = Time.now.to_i
    visit '/add_license?Version=alpha&LicenseNumber=238045632821817&NumLicenses=2&license_type=Standard'
    y = Time.now.to_i
    z = (y - x)
    puts "ROUND TRIP for: returns a valid view for a 2013 Standard version with two Licenses :  #{z.to_s} seconds"
    if z >= 5
      puts "\nEXITING DUE TO TIMEOUT\n"
    else
    #find('form div ul li label')['for'].should == '0000000000006800198'
    # page.should have_selector("#multiQuantity #license_options_list li", :text => "Add 1 User")
      expect(page).to have_button('Buy!')
      expect(page).to have_selector('.offer-link a' ,text: 'Purchase by phone')
      find('.offer-link a')['onclick']
      page.should have_selector(".offer-link a", :text => "Purchase by phone")
    end
  end

  ###################################################
  # Standard-3Licenses
  # license_no=ABCDE
  # license_type=Standard
  # version=alpha
  # Licenses=3
  ###################################################
  it 'returns a valid view for a 2013 Standard version with three Licenses' do
    LicenseAPI.should_receive(:validate_add_license).with("alpha", "123456789", "3", "Standard").and_return(
      {:code => 200,
      :body => {"license_offering_count" => "", "license_offerings" => [{"license_offer" => "1"}, {"license_offer" => "2"}], "offerings_from" => {"" => ""},
                "max_license_count" => "3", "maxReached" => "true", "availableLicenses" => "2", "unsupportedVersion" => "",
                "error" => ""},
      :error => nil})
    #pending
    x = Time.now.to_i
    visit '/add_license?Version=alpha&LicenseNumber=123456789&NumLicenses=3&license_type=Standard'
    y = Time.now.to_i
    z = (y - x)
    puts "ROUND TRIP for: returns a valid view for a 2013 Standard version with three Licenses :  #{z.to_s} seconds"
    if z >= 5
      puts "\nEXITING DUE TO TIMEOUT\n"
    else
      page.should have_content('You already have 3 users on this license.  Standard only supports up to 3 users per license.')
    end
  end

  #######################################
  # Standard-1Seat
  # license_no=ABCDE
  # license_type=Standard
  # version=beta
  # Licenses=1
  #######################################

  it 'returns a valid view for a I Standard version with one license' do
    LicenseAPI.should_receive(:validate_add_license).with("beta", "987654321", "1", "Standard").and_return(
      {:code => 200, 
      :body => {"license_offering_count" => "", "license_offerings" => [{"license_offer" => "1"}, {"license_offer" => "2"}], "offerings_from" => {"" => ""}, 
                "max_license_count" => "3", "maxReached" => "false", "availableLicenses" => "2", "unsupportedVersion" => "", 
                "error" => ""}, 
      :error => nil})
    #pending
    x = Time.now.to_i
    visit '/add_license?Version=beta&LicenseNumber=987654321&NumLicenses=1&license_type=Standard'
    y = Time.now.to_i
    z = (y - x)
    puts "ROUND TRIP FOR: returns a valid view for a I Standard version with one license :  #{z.to_s} seconds"
    if z >= 5
      puts "\nEXITING DUE TO TIMEOUT\n"
    else
      #find('li:nth(4) label')['for'].should == '0000000000010400043'
      #find('li:first label')['for'].should == '0000000000010400042'
      page.should have_selector("#multiQuantity #license_options_list li", :text => "Add 1 User")
      page.should have_selector("#multiQuantity #license_options_list li", :text => "Add 2 Users")
      expect(page).to have_button('Buy!')
      expect(page).to have_selector('.offer-link a' ,text: 'Purchase by phone')
      find('.offer-link a')['onclick']
      page.should have_selector(".offer-link a", :text => "Purchase by phone")
    end
  end

  #################################################
  # I-Standard-2Licenses
  # license_no=084092619564970
  # license_type=Standard
  # version=beta
  # Licenses=2
  #################################################
  it 'returns a valid view for a I Standard version with two Licenses' do
    #pending
    x = Time.now.to_i
    visit '/add_license?Version=beta&LicenseNumber=0840926195649703&NumLicenses=2&license_type=Standard'
    y = Time.now.to_i
    z = (y - x)
    puts "ROUND TRIP FOR: returns a valid view for a Standard version with two Licenses :  #{z.to_s} seconds"
    if z >= 5
      puts "\nEXITING DUE TO TIMEOUT\n"
    else
      page.should have_content('Need To Add More Licenses?')
      find('.offer-link a')['onclick']
      expect(page).to have_selector('.offer-link a' ,text: 'Purchase by phone')
    end
  end

  #################################################
  # I-Standard-2Licenses-3Licenses
  # license_no=809068394973323
  # license_type=Standard
  # version=beta
  # Licenses=3
  #################################################
  it 'returns a valid view for a I Standard version with three Licenses' do
    LicenseAPI.should_receive(:validate_add_license).with("beta", "809068394973323", "3", "Standard").and_return(
      {:code => 200, 
      :body => {"license_offering_count" => "", "license_offerings" => [{"license_offer" => "1"}, {"license_offer" => "2"}], "offerings_from" => {"" => ""}, 
                "max_license_count" => "3", "maxReached" => "true", "availableLicenses" => "2", "unsupportedVersion" => "", 
                "error" => ""}, 
      :error => nil})
    #pending
    x = Time.now.to_i
    visit '/add_license?Version=beta&LicenseNumber=809068394973323&NumLicenses=3&license_type=Standard'
    y = Time.now.to_i
    z = (y - x)
    puts "ROUND TRIP FOR: returns a valid view for a I Standard version with three Licenses :  #{z.to_s} seconds"
    if z >= 5
      puts "\nEXITING DUE TO TIMEOUT\n"
    else
    page.should have_content('You already have 3 users on this license.  Standard only supports up to 3 users per license. If you need additional users, please call 800-324-6214')
  end
end

  ##############################################
  # I-enterprise-1Seat
  # license_no=083564105774867
  # license_type=enterprise
  # version=beta
  # Licenses=1
  ##############################################
  it 'returns a valid view for a I enterprise version with one license' do
    LicenseAPI.should_receive(:validate_add_license).with("beta", "083564105774867", "1", "enterprise").and_return(
      {:code => 200, 
      :body => {"license_offering_count" => "", "license_offerings" => [{"license_offer" => "1"}, {"license_offer" => "2"}, {"license_offer" => "3"}, {"license_offer" => "4"}], "offerings_from" => {"" => ""}, 
                "max_license_count" => "4", "maxReached" => "false", "availableLicenses" => "2", "unsupportedVersion" => "", 
                "error" => ""}, 
      :error => nil})
    #pending
    x = Time.now.to_i
    visit '/add_license?Version=beta&LicenseNumber=083564105774867&NumLicenses=1&license_type=enterprise'
    y = Time.now.to_i
    z = (y - x)
    puts "ROUND TRIP FOR: returns a valid view for a I enterprise version with one license :  #{z.to_s} seconds"
    if z >= 5
      puts "\nEXITING DUE TO TIMEOUT\n"
    else
      #find('form div ul li:first label')['for'].should == '0000000000010400041'
      #find('form div ul li:nth(4) label')['for'].should == '0000000000010400046'
      #find('form div ul li:nth(3) label')['for'].should == '0000000000010400044'
      #find('form div ul li:nth(4) label')['for'].should == '0000000000010400045'

      page.should have_selector("#multiQuantity #license_options_list li", :text => "Add 1 User")
      page.should have_selector("#multiQuantity #license_options_list li", :text => "Add 2 Users")
      page.should have_selector("#multiQuantity #license_options_list li", :text => "Add 4 Users")
      expect(page).to have_button('Buy!')
      expect(page).to have_selector('.offer-link a' ,text: 'Purchase by phone')
      find('.offer-link a')['onclick']
      page.should have_selector(".offer-link a", :text => "Purchase by phone")
    end
  end

  ##############################################
  # I-enterprise-2Licenses
  # license_no=098765432
  # license_type=enterprise
  # version=beta
  # Licenses=2
  ##############################################
  it 'returns a valid view for an enterprise version with two Licenses' do
    LicenseAPI.should_receive(:validate_add_license).with("beta", "098765432", "2", "enterprise").and_return(
      {:code => 200, 
      :body => {"license_offering_count" => "", "license_offerings" => [{"license_offer" => "1"}, {"license_offer" => "2"}, {"license_offer" => "3"}, {"license_offer" => "4"}], "offerings_from" => {"" => ""}, 
                "max_license_count" => "4", "maxReached" => "false", "availableLicenses" => "2", "unsupportedVersion" => "", 
                "error" => ""}, 
      :error => nil})
    #pending
    x = Time.now.to_i
    visit '/add_license?Version=beta&LicenseNumber=098765432&NumLicenses=2&license_type=enterprise'
    y = Time.now.to_i
    z = (y - x)
    puts "ROUND TRIP FOR: returns a valid view for a I enterprise version with two Licenses :  #{z.to_s} seconds"
    if z >= 5
      puts "\nEXITING DUE TO TIMEOUT\n"
    else
      #find('li:nth(4) input')['value'].should == '0000000000010400044'
      #find('li:nth(3) input')['value'].should == '0000000000010400045'
      page.should have_selector("#multiQuantity #license_options_list li", :text => "Add 1 User")
      page.should have_selector("#multiQuantity #license_options_list li", :text => "Add 2 Users")
      page.should have_selector("#multiQuantity #license_options_list li", :text => "Add 3 Users")
      expect(page).to have_button('Buy!')
      expect(page).to have_selector('.offer-link a' ,text: 'Purchase by phone')
      find('.offer-link a')['onclick']
      page.should have_selector(".offer-link a", :text => "Purchase by phone")
    end
  end

  ###################################################
  # enterprise version
  # license_no=0123456789
  # license_type=enterprise
  # version=beta
  # Licenses=3
  ####################################################
  it 'returns a valid view for a I enterprise version with three Licenses' do
    LicenseAPI.should_receive(:validate_add_license).with("beta", "0123456789", "3", "enterprise").and_return(
      {:code => 200, 
      :body => {"license_offering_count" => "", "license_offerings" => [{"license_offer" => "1"}, {"license_offer" => "2"}], "offerings_from" => {"" => ""}, 
                "max_license_count" => "5", "maxReached" => "false", "availableLicenses" => "2", "unsupportedVersion" => "",
                "error" => ""}, 
      :error => nil})
    #pending
    x = Time.now.to_i
    visit '/add_license?Version=beta&LicenseNumber=0123456789&NumLicenses=3&license_type=enterprise'
    y = Time.now.to_i
    z = (y - x)
    puts "ROUND TRIP FOR: returns a valid view for a I enterprise version with three Licenses :  #{z.to_s} seconds"
    if z >= 5
      puts "\nEXITING DUE TO TIMEOUT\n"
    else
      #find('li:first input')['value'].should == '0000000000010400044'
      #find('li:nth(4) input')['value'].should == '0000000000010400045'
      page.should have_selector("#multiQuantity #license_options_list li", :text => "Add 1 User")
      page.should have_selector("#multiQuantity #license_options_list li", :text => "Add 2 Users")
      expect(page).to have_button('Buy!')
      expect(page).to have_selector('.offer-link a' ,text: 'Purchase by phone')
      find('.offer-link a')['onclick']
      page.should have_selector(".offer-link a", :text => "Purchase by phone")
    end
  end

  ######################################################
  # enterprise-4 Licenses
  # license_no=0123456789
  # license_type=enterprise
  # version=beta
  # Licenses=4
  #######################################################
  it 'returns a valid view for a I enterprise version with four Licenses' do
    LicenseAPI.should_receive(:validate_add_license).with("beta", "0123456789", "4", "enterprise").and_return(
        {:code => 200,
         :body => {"license_offering_count" => "", "license_offerings" => [{"license_offer" => "1"}, {"license_offer" => "2"}], "offerings_from" => {"" => ""},
                   "max_license_count" => "4", "maxReached" => "false", "availableLicenses" => "1", "unsupportedVersion" => "",
                   "error" => ""},
         :error => nil})
    #pending
    x = Time.now.to_i
    visit '/add_license?Version=beta&LicenseNumber=0123456789&NumLicenses=4&license_type=enterprise'
    y = Time.now.to_i
    z = (y - x)

    puts "\nROUNDTRIP FOR: for returns a valid view for a I enterprise version with four Licenses = " +z.to_s + "\n"

    if z.to_i >= 5
      puts "EXITING DUE TO TIMEOUT TEST \n"
    else

      #find('form div ul li input')['value'].should == '0000000000010400045'
      page.should have_selector("#multiQuantity #license_options_list li", :text => "Add 1 User")
      expect(page).to have_button('Buy!')
      expect(page).to have_selector('.offer-link a' ,text: 'Purchase by phone')
      find('.offer-link a')['onclick']
      page.should have_selector(".offer-link a", :text => "Purchase by phone")
      end
  end

  ####################################################
  # enterprise-5 Licenses
  # license_no=0123456789
  # license_type=enterprise
  # version=beta
  # Licenses=5
  ####################################################
  it 'returns a valid view for a I enterprise version with five Licenses' do
    LicenseAPI.should_receive(:validate_add_license).with("beta", "0123456789", "5", "enterprise").and_return(
        {:code => 200,
         :body => {"license_offering_count" => "", "license_offerings" => [{"license_offer" => "1"}, {"license_offer" => "2"}], "offerings_from" => {"" => ""},
                   "max_license_count" => "5", "maxReached" => "true", "availableLicenses" => "", "unsupportedVersion" => "",
                   "error" => ""},
         :error => nil})
    #pending
    x = Time.now.to_i
    visit '/add_license?Version=beta&LicenseNumber=0123456789&NumLicenses=5&license_type=enterprise'
    y = Time.now.to_i
    z = (y - x)
    puts "ROUND TRIP FOR:returns a valid view for a I enterprise version with five Licenses :  #{z.to_s} seconds"
    if z >= 5
      puts "\nEXITING DUE TO TIMEOUT\n"
    else
      page.should have_content 'You already have 5 users on this license.  enterprise only supports up to 5 users per license.'
    end
  end
end
