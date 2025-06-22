class CreateAllianceDuels < ActiveRecord::Migration[8.0]
  def change
    create_table :alliance_duels do |t|
      t.date :start_date
      t.references :alliance, null: false, foreign_key: true

      t.timestamps
    end
  end
end
