class AddMoreSpaceInVideoColumns < ActiveRecord::Migration
  def change
    change_column :videos, :speech, :string , :limit => nil
    change_column :videos, :audio_labels, :string ,:limit => nil
    change_column :videos, :video_labels, :string, :limit => nil
  end
end
