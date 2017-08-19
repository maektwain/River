class AddMoreFieldsToVideo < ActiveRecord::Migration
  def change
    add_column :videos, :analytics, :text
  end
end
