class AddAudioConfidenceToVideo < ActiveRecord::Migration
  def change
    add_column :videos, :audio_confidence, :decimal, :precision => 10, :scale => 10

  end
end
