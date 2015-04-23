require 'rails_helper'

PASSWORD = 'the password'
NEW_PASSWORD = 'the new password'

#TODO: review and rewrite all tests
RSpec.describe Item, type: :model do
  before do
    @user = User.create(name: 'name', email: 'email@email.com', password: 'password')
    @group = @user.add Group.new(name: 'group')
    @root = Directory.create(name: "root")
    @item = @group.add Item.new(username: 'x', password: PASSWORD, directory: @root), authorization_user: @user
    @item.save!
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
    describe "should be able to change the value of password" do
      before do 
        @loaded_item.authorize @user
        @loaded_item.password = NEW_PASSWORD
        @loaded_item.save!
        @loaded_item = Item.find(@item.id) # reload
      end
      it { expect(@loaded_item.password(authorization_user: @user)).to eq NEW_PASSWORD }
    end
  end
end

RSpec.describe Item, type: :model do
  before do 
    @users = 3.times.map{|i| User.create(name: "name#{i}", email: "email#{i}@example.com", password: "password#{i}")}
    @groups = @users.map{|user| user << Group.new(name: "group #{user.name}")}
    @groups.each_with_index {|group, i| group.authorize(@users[i])}
    @root = Directory.create(name: 'root')
    @items = @groups.map {|group| group << Item.new(username: "user form #{group.name}", password: "password for #{group.name}", directory: @root)}
    @items.each {|item| item.save!}
  end
  3.times.each do |i|
    it { expect(@users[i].items.count).to eq 1 }
    it { expect(@users[i].items.first.password(authorization_user: @users[i])).to eq "password for group #{@users[i].name}" }
  end
  describe "add item[1] to group[0], authorized by user[1]" do
    before do
      @groups[0].add @items[1], authorization_user: @users[1]
      @groups[0].save!
    end
    it { expect(@users[0].items.count).to eq 2 }
    it { expect(@users[0].items.last).to eq @items[1] }
    it "user[0] should be now able to read item[1] password" do
      expect(@items[1].password(authorization_user: @users[0])).to eq "password for group Name1"
    end
    it "but not item[2] password" do
      expect(@items[2].password(authorization_user: @users[0])).not_to eq "password for group Name2"
    end
  end
end

RSpec.describe Item, type: :model do
  before do 
    @users = 3.times.map{|i| User.create(name: "name#{i}", email: "email#{i}@example.com", password: "password#{i}")}
    @groups = @users.map{|user| user << Group.new(name: "group #{user.name}")}
    @root = Directory.create(name: 'root')
    @items = 3.times.map{|i| Item.create(username: "item#{i}", password: "password for Name#{i}", directory: @root)}
    @items.each_with_index do |item, i| 
      item.authorize(@users[i])
      item << @groups[i]
    end
  end
  describe "should contain good password" do 
    3.times.each do |i|
      it { expect(@users[i].items.count).to eq 1 }
      it { expect(@users[i].items.first.password(authorization_user: @users[i])).to eq "password for #{@users[i].name}" }
    end
  end
  describe "add item[1] to group[0], authorized by user[1]" do
    before do
      @items[1].add @groups[0], authorization_user: @users[1]
      @items[1].save!
    end
    it { expect(@items[1].groups.count).to eq 2 }
    it { expect(@users[0].items.count).to eq 2 }
    it { expect(@users[0].items.last).to eq @items[1] }
    it "user[0] should be now able to read item[1] password" do
      expect(@items[1].password(authorization_user: @users[0])).to eq "password for Name1"
    end
    it "but not item[2] password" do
      expect(@items[2].password(authorization_user: @users[0])).not_to eq "password for Name2"
    end
  end
end
