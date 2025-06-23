class AddAllianceIdToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :alliance_id, :integer
    add_index :users, :alliance_id
    add_foreign_key :users, :alliances
  end
end
