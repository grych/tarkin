# == Schema Information
#
# Table name: groups
#
#  id                      :integer          not null, primary key
#  name                    :string(256)      not null
#  public_key_pem          :string(4096)     not null
#  private_key_pem_crypted :binary           not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#

require 'rails_helper'

RSpec.describe Group, type: :model do
  it { should respond_to :public_key_pem }
  it { should respond_to :private_key_pem }
  describe "blank" do
    before do
      @group = Group.new
    end
    it { expect(@group).not_to be_valid }
  end
  describe "good" do
    before do
      @user = User.create(name: 'name', email: 'email@email.com', password: 'password')
      @group = @user.add_new_group Group.new(name: 'group')
    end
    it { expect(@group).to be_valid }
    describe "but not duplicated name" do
      before do
        @new_group = @user.add_new_group Group.new(name: 'group')
      end
      it { expect(@new_group).not_to be_valid }
    end
  end
end
