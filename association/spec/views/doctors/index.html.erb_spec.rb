require 'spec_helper'

describe "doctors/index" do
  before(:each) do
    assign(:doctors, [
      stub_model(Doctor,
        :name => "",
        :address => "",
        :city => "",
        :state => "",
        :zip => "",
        :school => "",
        :years_in_practise => "Years In Practise",
        :integer => "Integer"
      ),
      stub_model(Doctor,
        :name => "",
        :address => "",
        :city => "",
        :state => "",
        :zip => "",
        :school => "",
        :years_in_practise => "Years In Practise",
        :integer => "Integer"
      )
    ])
  end

  it "renders a list of doctors" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "".to_s, :count => 2
    assert_select "tr>td", :text => "".to_s, :count => 2
    assert_select "tr>td", :text => "".to_s, :count => 2
    assert_select "tr>td", :text => "".to_s, :count => 2
    assert_select "tr>td", :text => "".to_s, :count => 2
    assert_select "tr>td", :text => "".to_s, :count => 2
    assert_select "tr>td", :text => "Years In Practise".to_s, :count => 2
    assert_select "tr>td", :text => "Integer".to_s, :count => 2
  end
end
