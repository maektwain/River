class CreateVideos < ActiveRecord::Migration
  def change
    create_table :videos do |t|
      t.references :user, index: true, foreign_key: true
      t.string :video_hash,   limit: 250,   null:false
      t.string :video_storageUrl, limit: 250, null: false
      t.string :speech , limit: 3000,  null: false
      t.string :audio_url , limit: 250, null: false
      t.string :video_labels, limit: 400, null: false
      t.string :audio_labels, limit: 500, null: false
      t.boolean :proccesed , null: false, default: false
      t.integer :updated_by_id,                     null: false
      t.integer :created_by_id,                     null: false
      t.timestamps null: false
    end
  end
end
