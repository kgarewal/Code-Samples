require 'spec_helper'

describe "appointments/new" do
  before(:each) do
    assign(:appointment, stub_model(Appointment,
      :date_of_visit => "",
      :pet => "",
      :customer => "",
      :requires_reminder => "",
      :reason_for_visit => "MyString"
    ).as_new_record)
  end

  it "renders new appointment form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", appointments_path, "post" do
      assert_select "input#appointment_date_of_visit[name=?]", "appointment[date_of_visit]"
      assert_select "input#appointment_pet[name=?]", "appointment[pet]"
      assert_select "input#appointment_customer[name=?]", "appointment[customer]"
      assert_select "input#appointment_requires_reminder[name=?]", "appointment[requires_reminder]"
      assert_select "input#appointment_reason_for_visit[name=?]", "appointment[reason_for_visit]"
    end
  end
end
