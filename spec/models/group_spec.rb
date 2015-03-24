require 'rails_helper'

RSpec.describe Group, type: :model do
  it { should respond_to :public_key_pem }
  it { should respond_to :private_key_pem }
  it { should respond_to :public_key }
  it { should respond_to :private_key }
  describe "blank" do
    before do
      @group = Group.new
    end
    it { expect(@group).not_to be_valid }
  end

  describe "with user associated" do
    before do
      @user = User.create(name: 'name', email: 'email@email.com', password: 'password')
    end
    describe "to new group" do
      before do
        @group = Group.new(name: 'group')
        @group.add(@user)
        @group.save!
      end
      it { expect(@group).to be_valid }
      it "group should be saved" do 
        expect(@group.new_record?).to eq false
      end
      it "should not be able to read the private_key_pem without valid user" do
        expect{@group.private_key_pem}.to raise_error Tarkin::PrivateKeyNotAccessibleException 
      end
      describe "and duplicated name" do
        before do
          @new_group = Group.new(name: 'group')
        end
        it { expect(@new_group).not_to be_valid }
      end
    end

    describe "to existing group" do
      before do
        g = Group.new(name: 'group')
        g.add @user
        g.save!
        @group = Group.find_by(name: 'group')
      end
      it "private key should be readable" do 
        expect(@group.private_key(authorization_user: @user).class).to eq OpenSSL::PKey::RSA 
      end
      describe "but other user" do
        before do
          @user2 = User.create(name: 'name2', email: 'email2@email.com', password: 'password2')
        end
        it "should not be able to read the private_key" do
          expect{@group.private_key(authorization_user: @user2)}.to raise_error Tarkin::GroupNotAccessibleException
        end
        describe "added to the group" do
          describe "with authorization" do
            before do
              @group.authorize @user
              @group << @user2
            end
            it "should be able to read the private key" do
              expect(@group.private_key(authorization_user: @user2).class).to eq OpenSSL::PKey::RSA
            end
            it "group should be associated with two users" do
              expect(@group.users.count).to eq 2
            end
          end
          describe "without authorization" do
            it {expect{@group.add @user2}.to raise_error Tarkin::NotAuthorized}            
          end
        end
      end
    end

    describe "add existing item to the group" do
      before do
        @u1 = User.create(name: 'name1', email: 'email1@email.com', password: 'password1')
        @u2 = User.create(name: 'name2', email: 'email2@email.com', password: 'password2')
        g = Group.new(name: 'g1')
        g.add @u1
        g.save!
        g = Group.new(name: 'g2')
        g.add @u2
        g.save!

        @g1 = Group.find_by(name: 'g1')
        @g2 = Group.find_by(name: 'g2')
        @g1.authorize @u1
        @g2.authorize @u2

        @i1 = Item.new(username:'u1', password: 'i1')
        @i1.authorize @u1
        @i1 << @g1
        @i2 = Item.new(username:'u2', password: 'i2')
        @i2.authorize @u2
        @i2 << @g2

        # @i2.add @g1, authorization_user: @u2
        # @i2.save!
        @g1.add @i2, authorization_user: @u2
        @g1.save!
      end
      it { expect(@g1.items.count).to eq 2 }
      it { expect(@g1.items).to eq [@i1, @i2]}
      it { expect(@g2.items.count).to eq 1 }
      it { expect(@i1.password  authorization_user: @u1).to eq 'i1' }
      it { expect(@i2.password  authorization_user: @u2).to eq 'i2' }
      it { expect(@i2.password  authorization_user: @u1).to eq 'i2' } ###
      describe "loaded from database" do
        before do
          @u = User.find_by(email: 'email1@email.com'); @u.password = 'password1'
          @user2 = User.find_by(email: 'email2@email.com'); @user2.password = 'password2'
          @item1 = Item.first
          @item2 = Item.second
        end
        it { expect(@item1.password  authorization_user: @u).to eq 'i1' }
        it { expect(@item2.password  authorization_user: @u).to eq 'i2'}
        it { expect{@item1.password  authorization_user: @user2}.to raise_error Tarkin::ItemNotAccessibleException }
      end
    end

  end
end
