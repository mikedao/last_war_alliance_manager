class CreateAlliances < ActiveRecord::Migration[8.0]
  def change
    create_table :alliances do |t|
      t.string :name, null: false
      t.string :tag, null: false
      t.text :description, null: false
      t.string :server, null: false
      t.references :admin, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
    add_index :alliances, :tag, unique: true
  end
end
