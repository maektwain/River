class AddTextFieldsForStringInVideo < ActiveRecord::Migration
  def change
    change_column :videos, :speech, :text, limit: nil
  end
end
