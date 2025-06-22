class CreateDuelDayScores < ActiveRecord::Migration[8.0]
  def change
    create_table :duel_day_scores do |t|
      t.decimal :score
      t.references :duel_day, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true

      t.timestamps
    end
  end
end
