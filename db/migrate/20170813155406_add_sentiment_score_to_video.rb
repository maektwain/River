class AddSentimentScoreToVideo < ActiveRecord::Migration
  def change
    add_column :videos, :sentiment_score , :decimal, :precision => 10, :scale => 10
  end
end
