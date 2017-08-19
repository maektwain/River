class RemoveCreateAndUpdateInt < ActiveRecord::Migration
  def change

    remove_column :videos, :updated_by_id, :integer
    remove_column :videos, :created_by_id, :integer

  end
end
