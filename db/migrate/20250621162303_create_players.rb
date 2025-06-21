class CreatePlayers < ActiveRecord::Migration[8.0]
  def change
    create_table :players do |t|
      t.string :username, null: false
      t.string :rank, null: false
      t.integer :level, null: false
      t.text :notes
      t.boolean :active, null: false, default: true
      t.references :alliance, null: false, foreign_key: true

      t.timestamps
    end
  end
end
