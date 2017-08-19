class AddWalletAddressToUser < ActiveRecord::Migration
  def change
    add_column :users, :walletAddress, :string
  end
end
