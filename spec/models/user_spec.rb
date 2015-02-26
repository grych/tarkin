# == Schema Information
#
# Table name: users
#
#  id                      :integer          not null, primary key
#  name                    :string           not null
#  email                   :string(256)      not null
#  public_key_pem          :string(4096)     not null
#  private_key_pem_crypted :binary           not null
#  iv                      :binary           not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#

require 'rails_helper'

RSpec.describe User, type: :model do
  it { should respond_to :name }
  it { should respond_to :email }
  it { should respond_to :private_key }
  it { should respond_to :public_key }
  it { should respond_to :password }
  it { should respond_to :iv }
  describe "with no password given" do
    before do
      @user = User.new(name: 'name', email: 'email@email.com')
    end
    it { expect(@user).not_to be_valid }
  end
  describe "with given password" do
    before do
      @user = User.new(name: 'name', email: 'email@email.com', password: 'password')
    end
    it "should be valid, but not authenticated yet" do
      expect(@user).to be_valid 
      expect(@user.password).to eq "*" * 8
      expect(@user.public_key.class).to eq OpenSSL::PKey::RSA
      expect(@user.private_key.class).to eq OpenSSL::PKey::RSA
      expect(@user.authenticated?).to eq false
    end
    describe "when loading from the database" do
      before do
        @user.save!
        @loaded_user = User.find(@user.id)
      end
      it "saved user should be authenticated" do 
        expect(@user.authenticated?).to eq true 
      end
      it "without password" do
        expect(@loaded_user.password).to be_nil
        expect(@loaded_user.public_key.class).to eq OpenSSL::PKey::RSA
        expect{@loaded_user.private_key}.to raise_error(WrongPasswordException)
        expect(@loaded_user.authenticated?).to eq false
      end
      describe "with wrong password" do
        before do
          @loaded_user.password = "wrong"
        end
        it "should not be authenticated and not have valid private_key" do
          expect(@loaded_user.password).not_to be_nil
          expect(@loaded_user.public_key.class).to eq OpenSSL::PKey::RSA
          expect{@loaded_user.private_key}.to raise_error(WrongPasswordException)
          expect(@loaded_user.authenticated?).to eq false
        end
      end
      describe "with good password" do
        before do
          @loaded_user.password = "password"
        end
        it "should be authenticated and have valid private key" do
          expect(@loaded_user.password).not_to be_nil
          expect(@loaded_user.public_key.class).to eq OpenSSL::PKey::RSA
          expect(@loaded_user.private_key.class).to eq OpenSSL::PKey::RSA
          expect(@loaded_user.authenticated?).to eq true
        end
      end
    end
  end
end
