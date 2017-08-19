class AddCreateByIdAndUpdateById < ActiveRecord::Migration

    def change
      add_column :videos, :updated_by_id, :integer
      add_column :videos, :created_by_id, :integer
      add_foreign_key :videos, :users, column: :created_by_id
      add_foreign_key :videos, :users, column: :updated_by_id
  end
end
