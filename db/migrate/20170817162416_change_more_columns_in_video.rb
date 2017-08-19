class ChangeMoreColumnsInVideo < ActiveRecord::Migration
  def change

    add_column :videos, :audio_processed, :boolean, null: false, default: false
    add_column :videos, :audio_sample_rate, :integer

  end
end
