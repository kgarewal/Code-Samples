require 'spec_helper'

describe "appointments/edit" do
  before(:each) do
    @appointment = assign(:appointment, stub_model(Appointment,
      :date_of_visit => "",
      :pet => "",
      :customer => "",
      :requires_reminder => "",
      :reason_for_visit => "MyString"
    ))
  end

  it "renders the edit appointment form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", appointment_path(@appointment), "post" do
      assert_select "input#appointment_date_of_visit[name=?]", "appointment[date_of_visit]"
      assert_select "input#appointment_pet[name=?]", "appointment[pet]"
      assert_select "input#appointment_customer[name=?]", "appointment[customer]"
      assert_select "input#appointment_requires_reminder[name=?]", "appointment[requires_reminder]"
      assert_select "input#appointment_reason_for_visit[name=?]", "appointment[reason_for_visit]"
    end
  end
end
