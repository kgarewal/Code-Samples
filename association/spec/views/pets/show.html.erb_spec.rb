require 'spec_helper'

describe "pets/show" do
  before(:each) do
    @pet = assign(:pet, stub_model(Pet,
      :name => "Name",
      :type => "Type",
      :breed => "Breed",
      :age => 1,
      :weight => 2
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Name/)
    rendered.should match(/Type/)
    rendered.should match(/Breed/)
    rendered.should match(/1/)
    rendered.should match(/2/)
  end
end
