class AddLockedToDuelDays < ActiveRecord::Migration[8.0]
  def change
    add_column :duel_days, :locked, :boolean
  end
end
