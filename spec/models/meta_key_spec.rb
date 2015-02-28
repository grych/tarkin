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
      @group = @user.add Group.new(name: 'group')
    end
    it "should be able to add new group" do
      expect(@user.groups.count).to eq 1
    end
    it "should be able to read the groups private_key" do
      expect(@group.private_key_pem authorization_user:@user).not_to be_nil
      #expect(@user.group_private_key_pem(@group)).not_to be_nil
      #xpect(@user.group_private_key_pem(@group).length).to be > 0
    end
    describe "adding other user to the group" do
      before do
        @other_user = User.create(name: 'name', email: 'email2@email.com', password: 'new password')
        @other_user.add @group, authorization_user: @user
      end
      it "other user should be able to read the group private key" do
        expect(@group.private_key_pem authorization_user:@other_user).to eq @group.private_key_pem(authorization_user:@user)
      end
      describe "with the different group" do
        before do
          @new_group = @user.add Group.new(name: 'new group')
        end
        it "the other user should not be able to read the key" do
          expect{@new_group.private_key_pem(authorization_user: @other_user)}.to raise_error(Tarkin::GroupNotAccessibleException)
        end
        it "but the first user should read it" do
          expect(@new_group.private_key_pem(authorization_user: @user)).not_to be_nil
        end
        describe "after inviting the other user to a new group" do
          before do
            @new_group.add @other_user, authorization_user: @user
          end
          it "the new group password should be readable" do
            expect(@new_group.private_key_pem(authorization_user: @other_user)).not_to be_nil
          end
        end
      end
    end
  end
end
