class CreateDuelDays < ActiveRecord::Migration[8.0]
  def change
    create_table :duel_days do |t|
      t.integer :day_number
      t.string :name
      t.decimal :score_goal
      t.references :alliance_duel, null: false, foreign_key: true

      t.timestamps
    end
  end
end
