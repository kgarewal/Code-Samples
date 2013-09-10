require 'spec_helper'

describe "doctors/edit" do
  before(:each) do
    @doctor = assign(:doctor, stub_model(Doctor,
      :name => "",
      :address => "",
      :city => "",
      :state => "",
      :zip => "",
      :school => "",
      :years_in_practise => "MyString",
      :integer => "MyString"
    ))
  end

  it "renders the edit doctor form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", doctor_path(@doctor), "post" do
      assert_select "input#doctor_name[name=?]", "doctor[name]"
      assert_select "input#doctor_address[name=?]", "doctor[address]"
      assert_select "input#doctor_city[name=?]", "doctor[city]"
      assert_select "input#doctor_state[name=?]", "doctor[state]"
      assert_select "input#doctor_zip[name=?]", "doctor[zip]"
      assert_select "input#doctor_school[name=?]", "doctor[school]"
      assert_select "input#doctor_years_in_practise[name=?]", "doctor[years_in_practise]"
      assert_select "input#doctor_integer[name=?]", "doctor[integer]"
    end
  end
end
