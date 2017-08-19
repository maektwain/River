class UpdateVideoNullValues < ActiveRecord::Migration
  def change

    change_column :videos , :video_hash, :string , :null => true
    change_column :videos, :speech, :string, :null => true
    change_column :videos, :audio_url, :string, :null => true
    change_column :videos, :video_labels, :string, :null => true
    change_column :videos, :audio_labels, :string, :null => true

  end
end
