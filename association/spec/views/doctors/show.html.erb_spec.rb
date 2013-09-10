require 'spec_helper'

describe "doctors/show" do
  before(:each) do
    @doctor = assign(:doctor, stub_model(Doctor,
      :name => "",
      :address => "",
      :city => "",
      :state => "",
      :zip => "",
      :school => "",
      :years_in_practise => "Years In Practise",
      :integer => "Integer"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(//)
    rendered.should match(//)
    rendered.should match(//)
    rendered.should match(//)
    rendered.should match(//)
    rendered.should match(//)
    rendered.should match(/Years In Practise/)
    rendered.should match(/Integer/)
  end
end
