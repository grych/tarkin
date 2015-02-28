# == Schema Information
#
# Table name: items
#
#  id               :integer          not null, primary key
#  password_crypted :binary
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

require 'rails_helper'

PASSWORD = 'the password'

RSpec.describe Item, type: :model do
  before do
    @user = User.create(name: 'name', email: 'email@email.com', password: 'password')
    @group = @user.add Group.new(name: 'group')
    @item = @group.add Item.new(password: PASSWORD), authorization_user: @user
  end
  it "should have the crypted password" do
    expect(@item.password_crypted).to_not be_nil
  end
  it "should return the password in context of the user" do
    expect(@item.password(authorization_user: @user)).to eq PASSWORD
  end
  describe "even when reloaded from DB" do
    before do
      @loaded_user = User.find(@user.id)
      @loaded_user.password = 'password'
      @loaded_item = Item.find(@item.id)
    end
    it ", the password should be readable" do
      #expect(@loaded_user.item_password(@loaded_item)).to eq PASSWORD
      expect(@loaded_item.password(authorization_user: @user)).to eq PASSWORD
    end
  end
end
