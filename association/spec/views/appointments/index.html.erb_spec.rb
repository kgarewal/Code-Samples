require 'spec_helper'

describe "appointments/index" do
  before(:each) do
    assign(:appointments, [
      stub_model(Appointment,
        :date_of_visit => "",
        :pet => "",
        :customer => "",
        :requires_reminder => "",
        :reason_for_visit => "Reason For Visit"
      ),
      stub_model(Appointment,
        :date_of_visit => "",
        :pet => "",
        :customer => "",
        :requires_reminder => "",
        :reason_for_visit => "Reason For Visit"
      )
    ])
  end

  it "renders a list of appointments" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "".to_s, :count => 2
    assert_select "tr>td", :text => "".to_s, :count => 2
    assert_select "tr>td", :text => "".to_s, :count => 2
    assert_select "tr>td", :text => "".to_s, :count => 2
    assert_select "tr>td", :text => "Reason For Visit".to_s, :count => 2
  end
end
