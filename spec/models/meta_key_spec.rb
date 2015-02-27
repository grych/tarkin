# == Schema Information
#
# Table name: meta_keys
#
#  id          :integer          not null, primary key
#  key_crypted :binary           not null
#  iv_crypted  :binary           not null
#  user_id     :integer
#  group_id    :integer
#  item_id     :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'rails_helper'

RSpec.describe MetaKey, type: :model do
  it { should respond_to :key_crypted }
  it { should respond_to :iv_crypted }
  describe "valid user" do
    before do
      @user = User.create(name: 'name', email: 'email@email.com', password: 'password')
      @group = @user.add_new_group Group.new(name: 'group')
    end
    it "should be able to add new group" do
      expect(@user.groups.count).to eq 1
    end
    it "should be able to read the groups private_key" do
      expect(@user.group_private_key_pem(@group)).not_to be_nil
      expect(@user.group_private_key_pem(@group).length).to be > 0
    end
    it "key should be readable from both user and group context" do
      expect(@user.group_private_key_pem(@group)).to eq @group.private_key_pem(@user)
    end
    describe "adding other user to the group" do
      before do
        @other_user = User.create(name: 'name', email: 'email2@email.com', password: 'new password')
        @user.add_other_user_to_group @other_user, @group
      end
      it "other user should be able to read the group private key" do
        expect(@other_user.group_private_key_pem(@group)).not_to be_nil
        expect(@other_user.group_private_key_pem(@group)).to eq @user.group_private_key_pem(@group)
      end
      describe "with the different group" do
        before do
          @new_group = @user.add_new_group Group.new(name: 'new group')
        end
        it "the other user should not be able to read the key" do
          expect{@other_user.group_private_key_pem(@new_group)}.to raise_error(GroupNotAccessibleException)
        end
        it "but the first user should read it" do
          expect(@user.group_private_key_pem(@new_group)).not_to be_nil
        end
        describe "after inviting the other user to a new group" do
          before do
            @user.add_other_user_to_group @other_user, @new_group
          end
          it "the new group password should be readable" do
            expect(@other_user.group_private_key_pem(@new_group)).not_to be_nil
          end
        end
      end
    end
  end
end
